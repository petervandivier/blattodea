#!/usr/bin/env pwsh
#Requires -Module blattodea

[CmdletBinding()]
param (
    [Parameter()]
    # TODO: https://vexx32.github.io/2018/11/29/Dynamic-ValidateSet/
    [ValidateSet('Default','Remote1')]
    [string]
    $Position = 'Default'
)

$PopRegion = (Get-DefaultAWSRegion).Region
$PushRegion = $btd_VPC.$Position.Region
Set-DefaultAWSRegion $PushRegion

$vpc = Get-Content "./conf/actual/VPC.$Position.json" | ConvertFrom-Json
$igw = Get-Content "./conf/actual/IGW.$Position.json" | ConvertFrom-Json

$sg_id = New-EC2SecurityGroup -GroupName $btd_SecurityGroup.GroupName -Description $btd_SecurityGroup.Description -VpcId $vpc.VpcId
New-EC2Tag -Resource $sg_id -Tag $btd_SecurityGroup.Tags
New-EC2Tag -Resource $sg_id -Tag $btd_CommonTags.ToTagArray()

# https://docs.aws.amazon.com/sdkfornet/v3/apidocs/index.html?page=EC2/TEC2IpPermission.html&tocid=Amazon_EC2_Model_IpPermission

$btd_IpPermissions.SetSecurityGroup($sg_id)
$btd_IpPermissions.SetMyIp()
Grant-EC2SecurityGroupIngress -GroupId $sg_id -IpPermission $btd_IpPermissions

$rtb = Get-EC2RouteTable -Filter @{Name='vpc-id';Values=$vpc.VpcId}

New-EC2Tag -ResourceId $rtb.RouteTableId -Tag $btd_CommonTags.ToTagArray()
New-EC2Route -RouteTableId $rtb.RouteTableId -GatewayId $igw.InternetGatewayId -DestinationCidrBlock '0.0.0.0/0' | Out-Null 

Get-EC2SecurityGroup $sg_id | ConvertTo-Json -Depth 5 | Set-Content "./conf/actual/SecurityGroup.$Position.json" -Force

Set-DefaultAWSRegion $PopRegion
