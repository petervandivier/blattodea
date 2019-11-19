#!/usr/bin/env pwsh

[CmdletBinding()]
param (
    [Parameter()]
    [ValidateSet([ValidBtdPositionGenerator])]
    [string]
    $acceptPosition  = 'Remote1',

    [Parameter()]
    [ValidateSet([ValidBtdPositionGenerator])]
    [string]
    $requestPosition = 'Default'
)

# to seek level-two common values in level-1 nodes with arbitrary names:
#   $peer.PSObject.Properties.Value.* for non-hashtable support
#   $peer.Values.* for hashtable or non-hashtable
#   HT @chrisident / @vexx32 - https://powershell.slack.com/archives/C1RCWRDL4/p1572357830108900
$script:peer = Get-Content "./conf/actual/pcx-$acceptPosition-$requestPosition.json" | ConvertFrom-Json 

Remove-EC2VpcPeeringConnection `
    -VpcPeeringConnectionId $peer.VpcPeeringConnectionId `
    -Region $btd_VPC.$requestPosition.Region `
    -Confirm:$false 

$script:acceptRtb  = Get-Content "./conf/actual/RTB.$acceptPosition.json"  | ConvertFrom-Json
$script:requestRtb = Get-Content "./conf/actual/RTB.$requestPosition.json" | ConvertFrom-Json

$requestCidr = $peer.RequesterVpcInfo.CidrBlock
$acceptCidr = $peer.AccepterVpcInfo.CidrBlock

# TODO: ¿check for status:Blackhole first? 
Remove-EC2Route `
    -RouteTableId $requestRtb.RouteTableId `
    -DestinationCidrBlock $acceptCidr `
    -Region $peer.RequesterVpcInfo.Region `
    -Confirm:$false

Remove-EC2Route `
    -RouteTableId $acceptRtb.RouteTableId `
    -DestinationCidrBlock $requestCidr `
    -Region $peer.AccepterVpcInfo.Region `
    -Confirm:$false

$script:acceptSg  = Get-Content "./conf/actual/SecurityGroup.$acceptPosition.json"  | ConvertFrom-Json
$script:requestSg = Get-Content "./conf/actual/SecurityGroup.$requestPosition.json" | ConvertFrom-Json

$acceptSg  = Get-EC2SecurityGroup -GroupId $acceptSg.GroupId  -Region $peer.AccepterVpcInfo.Region
$requestSg = Get-EC2SecurityGroup -GroupId $requestSg.GroupId -Region $peer.RequesterVpcInfo.Region

# need to troubleshoot re-grant for port 80 if we allow cross-region traffic on 80
# just removing 80 from peering config for the moment
foreach($perm in ($acceptSg.IpPermission | Where-Object {$_.IpRange -contains $requestCidr})){
    Revoke-EC2SecurityGroupIngress `
        -GroupId $acceptSg.GroupId `
        -Region $peer.AccepterVpcInfo.Region `
        -IpPermission $perm 

    $perm.IpRange.Remove($requestCidr) | Out-Null # IpRanges <=> IpRange
    $perm.Ipv4Ranges = $perm.Ipv4Ranges | Where-Object CidrIp -ne $requestCidr

    Grant-EC2SecurityGroupIngress `
        -GroupId $acceptSg.GroupId `
        -Region $peer.AccepterVpcInfo.Region `
        -IpPermission $perm 
}

foreach($perm in ($requestSg.IpPermission | Where-Object {$_.IpRange -contains $acceptCidr})){
    Revoke-EC2SecurityGroupIngress `
        -GroupId $requestSg.GroupId `
        -Region $peer.RequesterVpcInfo.Region `
        -IpPermission $perm 

    $perm.IpRange.Remove($acceptCidr) | Out-Null
    $perm.Ipv4Ranges = $perm.Ipv4Ranges | Where-Object CidrIp -ne $acceptCidr
    
    Grant-EC2SecurityGroupIngress `
        -GroupId $requestSg.GroupId `
        -Region $peer.RequestVpcInfo.Region `
        -IpPermission $perm 
}
