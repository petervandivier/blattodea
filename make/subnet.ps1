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

$vpc = Get-Content "./conf/actual/VPC.$Position.json" | ConvertFrom-Json

$subnets = @()

foreach($sn in $btd_Subnets.$Position){
# New-EC2Subnet doesn't accept tags and i can't think of a sensible way to splat 
    $Subnet = New-EC2Subnet -VpcId $vpc.VpcId -CidrBlock $sn.CidrBlock -AvailabilityZone $sn.AvailabilityZone
    New-EC2Tag -ResourceId $Subnet.SubnetId -Tag $sn.Tags
    New-EC2Tag -ResourceId $Subnet.SubnetId -Tag $btd_CommonTags.ToTagArray()

    $subnets += $Subnet.SubnetId
}

$subnets = Get-EC2Subnet -SubnetId $subnets
$subnets | ConvertTo-Json -Depth 5 | Set-Content "./conf/actual/Subnets.$Position.json" -Force

$igw = New-EC2InternetGateway
New-EC2Tag -ResourceId $igw.InternetGatewayId -Tag $btd_CommonTags.ToTagArray()
Add-EC2InternetGateway -VpcId $vpc.VpcId -InternetGatewayId $igw.InternetGatewayId
$igw = Get-EC2InternetGateway -InternetGatewayId $igw.InternetGatewayId
$igw | ConvertTo-Json -Depth 5 | Set-Content "./conf/actual/IGW.$Position.json" -Force

Set-DefaultAWSRegion $PopRegion
