#!/usr/bin/env pwsh
#Requires -Module blattodea

$vpc = New-EC2Vpc -CidrBlock $btd_VPC.Primary.CidrBlock
New-EC2Tag -ResourceId $vpc.VpcId -Tag $btd_VPC.Primary.Tags
New-EC2Tag -ResourceId $vpc.VpcId -Tag $btd_CommonTags.ToTagArray()
$vpc = Get-EC2Vpc -VpcId $vpc.VpcId # do we need to refresh?
$vpc | ConvertTo-Json -Depth 5 | Set-Content ./conf/actual/VPC.json -Force

Get-EC2SecurityGroup -Filter @{Name='vpc-id';Value=$vpc.VpcId} | ForEach-Object {
    New-EC2Tag -ResourceId $_.GroupId -Tag @{Key='Name';Value='sg-vpc-crdb-default'}
    New-EC2Tag -ResourceId $_.GroupId -Tag $btd_CommonTags.ToTagArray()
}

Get-EC2RouteTable -Filter @{Name='vpc-id';Value=$vpc.VpcId} | ForEach-Object {
    New-EC2Tag -ResourceId $_.RouteTableId -Tag @{Key='Name';Value='rtb-crdb'}
    New-EC2Tag -ResourceId $_.RouteTableId -Tag $btd_CommonTags.ToTagArray()
}

Get-EC2NetworkAcl -Filter @{Name='vpc-id';Value=$vpc.VpcId} | ForEach-Object {
    New-EC2Tag -ResourceId $_.NetworkAclId -Tag @{Key='Name';Value='acl-crdb'}
    New-EC2Tag -ResourceId $_.NetworkAclId -Tag $btd_CommonTags.ToTagArray()
}

# we're just using the default dchp options set at this time
# don't clobber tags for dhcp options sets shared by other VPCs
# New-EC2Tag -ResourceId $vpc.DhcpOptionsId -Tag @{Key='Name';Value='dopt-crdb'}
# New-EC2Tag -ResourceId $vpc.DhcpOptionsId -Tag $btd_CommonTags.ToTagArray()
