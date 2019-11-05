#!/usr/bin/env pwsh
#Requires -Module blattodea

$subnets = Get-Content ./conf/actual/Subnets.json | ConvertFrom-Json
$sg_id = (Get-Content ./conf/actual/SecurityGroup.json | ConvertFrom-Json).GroupId
$kp = Get-Content ./conf/actual/KeyPair.json | ConvertFrom-Json

# $identFile = Resolve-Path "./conf/secret/$($kp.KeyName).pem"
$ami = Invoke-Expression ($btd_JumpBox.EC2.Image.Query -join '')

$image_splat = @{
    AssociatePublicIp = $true
    ImageId = $ami.ImageId
    KeyName = $kp.KeyName
    SecurityGroupId = $sg_id
    InstanceType = $btd_JumpBox.EC2.InstanceType
    BlockDeviceMapping = @{
        DeviceName="/dev/sda1"
        Ebs = @{
            DeleteOnTermination = $true
        }
    }
    SubnetId = ($subnets | Where-Object AvailabilityZone -eq $btd_JumpBox.AvailabilityZone)[0].SubnetId
    TagSpecification = (ConvertTo-EC2TagSpec -Tags $btd_CommonTags -ResourceType 'instance')
}

$n = New-EC2Instance @image_splat
New-EC2Tag -Resource $n.RunningInstance.InstanceId -Tag @{Key='Name';Value=$btd_JumpBox.Name}
$getN = [scriptblock]{Get-EC2Instance -InstanceId $n.Instances[0].InstanceId}
$n = & $getN

# copy instance tags to underlying volumes
foreach($node in ($n.Instances)){
    foreach($device in ($node.BlockDeviceMappings.Ebs.VolumeId)){
        $node.Tags | ForEach-Object {
            New-EC2Tag -Resource $device -Tag $_
        }
    }
}

while((& $getN).Instances.State.Name -ne 'running'){
    Write-Host "Awaiting startup of $($btd_JumpBox.Name). Sleeping 10..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
} 

foreach($node in (& $getN).Instances) {
    $nodeName = ($node.Tags | Where-Object Key -eq Name).Value
    $ip = $node.PublicIpAddress
    $identFile = Resolve-Path "./conf/secret/$($node.KeyName).pem"

    if('alive' -ne (dsh -i $identFile -o ConnectTimeout=10 centos@$ip 'echo -n "alive"')){
        do {   
            if(0 -eq ($i % 6)){ Write-Host "-- You may press ctrl+c to abort. This is the last step in make/jumpbox" -ForegroundColor Blue }
            $i++

            Write-Host "Awaiting sshd startup on EC2 instance $nodeName. Sleeping 10..." -ForegroundColor Yellow
            Start-Sleep -Seconds 10
        } until ('alive' -eq (dsh -i $identFile -o ConnectTimeout=10 centos@$ip 'echo -n "alive"'))
    }

    dsh -i $identFile centos@$ip "sudo hostnamectl set-hostname '$($nodeName)'"
}

& $getN | ConvertTo-Json -Depth 10 | Set-Content ./conf/actual/JumpBox.json -Force
# https://www.cockroachlabs.com/docs/stable/deploy-cockroachdb-on-aws.html#step-9-run-a-sample-workload
