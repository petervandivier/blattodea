#!/usr/bin/env pwsh
#Requires -Module blattodea

$subnets = Get-Content ./conf/actual/Subnets.json | ConvertFrom-Json
$sg_id = (Get-Content ./conf/actual/SecurityGroup.json | ConvertFrom-Json).GroupId

if((Get-EC2KeyPair).KeyName -contains $btd_Defaults.KeyPair.Name){
    $btd_Defaults.KeyPair.Name = "$($btd_Defaults.KeyPair.Name)_$(Get-Random)"
    Write-Warning "Duplicate Key Pair Name detected."
    Write-Warning "Hot-swapping KeyName in conf. New name is '$($btd_Defaults.KeyPair.Name)'."
}

$kp = New-EC2KeyPair -KeyName $btd_Defaults.KeyPair.Name

$sshKey = "conf/secret/$($btd_Defaults.KeyPair.Name).pem"

$kp.KeyMaterial | Set-Content $sshKey -Force
$kp | Select-Object KeyFingerprint, KeyName | ConvertTo-Json | Set-Content ./conf/actual/KeyPair.json -Force

$sshKey = Resolve-Path $sshKey

chmod 0600 $sshKey

# ⸘ImageIds vary between regions for the same image‽ 
$ami = Invoke-Expression ($btd_Defaults.EC2.Image.Query -join '')
$ami | ConvertTo-Json -Depth 5 | Set-Content ./conf/actual/AMI.json -Force

$image_splat = @{
    AssociatePublicIp = $true # TODO: deploy config via user data and rm public IP
    ImageId = $ami.ImageId
    KeyName = $kp.KeyName
    SecurityGroupId = $sg_id
    InstanceType = $btd_Defaults.EC2.InstanceType
    BlockDeviceMapping = @{
        DeviceName="/dev/sda1"
        Ebs = @{
            DeleteOnTermination = $true
        }
    }
    SubnetId = [string]$null
    TagSpecification = (ConvertTo-EC2TagSpec -Tags $btd_CommonTags -ResourceType 'instance')
}
$cluster = @()

foreach($sn in $subnets){
    $image_splat.SubnetId = $sn.SubnetId
    $n = New-EC2Instance @image_splat
    $cluster += $n
}

$cluster = Get-EC2Instance -InstanceId $cluster.Instances.InstanceId
# TODO: add method to cluster object to self-update SMO-style
# Add-Member -InputObject $cluster -Name Sync -Value {$this = (Get-EC2Instance @($cluster.Instances.InstanceId))}

$cluster.RunningInstance.InstanceId | ForEach-Object {
    $i+=1
    $name = $btd_Defaults.EC2.NamePattern -f $i
    New-EC2Tag -Resource $_ -Tag @([Amazon.EC2.Model.Tag]::new('Name',$name))
}

$cluster = Get-EC2Instance @($cluster.Instances.InstanceId)

# copy instance tags to underlying volumes
foreach($node in ($cluster.Instances)){
    foreach($device in ($node.BlockDeviceMappings.Ebs.VolumeId)){
        $node.Tags | ForEach-Object {
            New-EC2Tag -Resource $device -Tag $_
        }
    }
}

$cluster = Get-EC2Instance @($cluster.Instances.InstanceId)
$cluster  | ConvertTo-Json -Depth 5 | Set-Content ./conf/actual/Cluster.json -Force

$getEc2 = [scriptblock]{Get-EC2Instance @($cluster.Instances.InstanceId)}

while((& $getEc2).Instances.State.Name -ne 'running'){
    Write-Host "Awaiting startup of all EC2 instances. Sleeping 5..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
} 

Write-Host "$(Get-Date) : all nodes report running" -ForegroundColor Blue

$cluster = (& $getEc2)

$cluster  | ConvertTo-Json -Depth 5 | Set-Content ./conf/actual/Cluster.json -Force

foreach($node in $cluster.Instances) {
    $nodeName = ($node.Tags | Where-Object Key -eq Name).Value
    $ip = $node.PublicIpAddress

    if('alive' -ne (dsh -i $sshKey -o ConnectTimeout=10 centos@$ip 'echo -n "alive"')){
        do {   
            if(0 -eq ($i % 6)){ Write-Host "-- You may press ctrl+c to abort. This is the last step in make/cluster" -ForegroundColor Blue }
            $i++

            Write-Host "Awaiting sshd startup on EC2 instance $nodeName. Sleeping 5..." -ForegroundColor Yellow
            Start-Sleep -Seconds 5
        } until ('alive' -eq (dsh -i $sshKey -o ConnectTimeout=10 centos@$ip 'echo -n "alive"'))
    }

# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/set-time.html
    dcp -i $sshKey ./templates/default/mk-chrony.sh "centos@$ip`:/tmp/"
    dsh -i $sshKey centos@$ip 'sudo /tmp/mk-chrony.sh'
}
