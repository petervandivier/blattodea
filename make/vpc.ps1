#!/usr/bin/env pwsh
#Requires -Module blattodea

$vpc = New-EC2Vpc -CidrBlock $btd_VPC.CidrBlock
New-EC2Tag -ResourceId $vpc.VpcId -Tag $btd_Defaults.VPC.Tags
New-EC2Tag -ResourceId $vpc.VpcId -Tag $btd_CommonTags.ToTagArray()
$vpc = Get-EC2Vpc -VpcId $vpc.VpcId # do we need to refresh?
$vpc | ConvertTo-Json -Depth 5 | Set-Content ./conf/actual/VPC.json -Force

Get-EC2SecurityGroup -Filter @{Name='vpc-id';Value=$vpc.VpcId} | ForEach-Object {
    New-EC2Tag -ResourceId $_.GroupId -Tag @{Key='Name';Value='cockroachdb-vpc-default'}
    New-EC2Tag -ResourceId $_.GroupId -Tag $btd_CommonTags.ToTagArray()
}
