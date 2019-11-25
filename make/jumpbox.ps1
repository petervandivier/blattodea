#!/usr/bin/env pwsh
#Requires -Module blattodea

[CmdletBinding()]
param (
    [Parameter()]
    [ValidateSet([ValidBtdPositionGenerator])]
    [string]
    $Position = 'Default'
)

$PopRegion = $StoredAWSRegion
$PushRegion = $btd_VPC.$Position.Region
Set-DefaultAWSRegion $PushRegion

$subnets = Get-Content "./conf/actual/Subnets.$Position.json" | ConvertFrom-Json
$sg_id = (Get-Content "./conf/actual/SecurityGroup.$Position.json" | ConvertFrom-Json).GroupId
$kp = Get-Content "./conf/actual/KeyPair.json" | ConvertFrom-Json

$certsDirectory = Resolve-Path $btd_Defaults.CertsDirectory

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

$caKey = "$certsDirectory/my-safe-directory/ca.key"
if(Test-Path $caKey){
    $clientCerts = "$certsDirectory/client"
    New-Item -Type Directory -Path $clientCerts

    foreach($usr in $btd_Users){
        cockroach cert create-client --certs-dir="$certsDirectory/certs/" --ca-key=$caKey $usr.username
        Move-Item "$certsDirectory/certs/*$($usr.username)*" $clientCerts
        Copy-Item "$certsDirectory/certs/ca.crt" $clientCerts
    }
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

    dcp -i $identFile "./templates/initdb/getbin.sh" centos@$ip`:~/
    dcp -r -i $identFile $clientCerts centos@$ip`:~/
    dsh -i $identFile centos@$ip "chmod +x ./getbin.sh && sudo ./getbin.sh"
    dsh -i $identFile centos@$ip "sudo hostnamectl set-hostname '$($nodeName)'"
}

Remove-Item $clientCerts -Recurse
# Write-Host $clientCerts -ForegroundColor Green

# TODO: properly inventory jumpboxes
& $getN | ConvertTo-Json -Depth 10 | Set-Content "./conf/actual/JumpBox.$Position.json" -Force
# https://www.cockroachlabs.com/docs/stable/deploy-cockroachdb-on-aws.html#step-9-run-a-sample-workload

Set-DefaultAWSRegion $PopRegion
