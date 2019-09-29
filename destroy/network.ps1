#!/usr/bin/env pwsh

$vpc =  Get-Content ./conf/actual/VPC.json           | ConvertFrom-Json
$sn  =  Get-Content ./conf/actual/Subnets.json       | ConvertFrom-Json

$sn.SubnetId | Remove-EC2Subnet -Confirm:$false

Remove-EC2Vpc -VpcId $vpc.VpcId -Confirm:$false
