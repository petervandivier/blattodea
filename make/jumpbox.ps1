#!/usr/bin/env pwsh
#Requires -Module blattodea

$subnets = Get-Content ./conf/actual/Subnets.json | ConvertFrom-Json
$sg_id = (Get-Content ./conf/actual/SecurityGroup.json | ConvertFrom-Json).GroupId
$kp = Get-Content ./conf/actual/KeyPair.json | ConvertFrom-Json

# $sshKey = Resolve-Path "./conf/secret/$($kp.KeyName).pem"
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

while($null -eq $n.PublicIpAddress){
    Write-Host "Awaiting PublicIPAddress assignment for $($btd_JumpBox.Name)" -ForegroundColor Yellow
    $n = & $getN
}
$n | ConvertTo-Json -Depth 10 | Set-Content ./conf/actual/JumpBox.json -Force
# https://www.cockroachlabs.com/docs/stable/deploy-cockroachdb-on-aws.html#step-9-run-a-sample-workload
