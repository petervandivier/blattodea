#!/usr/bin/env pwsh

# still only works for 2 regions

# to seek level-two common values in level-1 nodes with arbitrary names:
#   $peer.PSObject.Properties.Value.* for non-hashtable support
#   $peer.Values.* for hashtable or non-hashtable
#   HT @chrisident / @vexx32 - https://powershell.slack.com/archives/C1RCWRDL4/p1572357830108900
$script:peer = Get-Content "./conf/actual/Peering.json" | ConvertFrom-Json 

Remove-EC2VpcPeeringConnection -VpcPeeringConnectionId $peer.VpcPeeringConnectionId -Confirm:$false

$script:acceptPosition  = 'Remote1'
$script:requestPosition = 'Default'

$script:acceptRtb  = Get-Content "./conf/actual/RTB.$acceptPosition.json"  | ConvertFrom-Json
$script:requestRtb = Get-Content "./conf/actual/RTB.$requestPosition.json" | ConvertFrom-Json

# TODO: ¿check for status:Blackhole first? 
Remove-EC2Route `
    -RouteTableId $requestRtb.RouteTableId `
    -DestinationCidrBlock $peer.AccepterVpcInfo.CidrBlock `
    -Region $peer.RequesterVpcInfo.Region `
    -Confirm:$false

Remove-EC2Route `
    -RouteTableId $acceptRtb.RouteTableId `
    -DestinationCidrBlock $peer.RequesterVpcInfo.CidrBlock `
    -Region $peer.AccepterVpcInfo.Region `
    -Confirm:$false

$script:acceptSg  = Get-Content "./conf/actual/SecurityGroup.$acceptPosition.json"  | ConvertFrom-Json
$script:requestSg = Get-Content "./conf/actual/SecurityGroup.$requestPosition.json" | ConvertFrom-Json

$acceptSg  = Get-EC2SecurityGroup -GroupId $acceptSg.GroupId  -Region $peer.AccepterVpcInfo.Region
$requestSg = Get-EC2SecurityGroup -GroupId $requestSg.GroupId -Region $peer.RequesterVpcInfo.Region

# TODO: better filter handling for perms wipe

# foreach($perm in ($acceptSg.IpPermission | Where-Object {$_.IpRange -eq $peer.RequesterVpcInfo.CidrBlock})){
#     Revoke-EC2SecurityGroupIngress `
#         -GroupId $acceptSg.GroupId `
#         -Region $peer.AccepterVpcInfo.Region `
#         -IpPermission $perm `
#         -Verbose
# }

# foreach($perm in ($requestSg.IpPermission | Where-Object {$_.IpRange -eq $peer.AccepterVpcInfo.CidrBlock})){
#     Revoke-EC2SecurityGroupIngress `
#         -GroupId $requestSg.GroupId `
#         -Region $peer.RequesterVpcInfo.Region `
#         -IpPermission $perm `
#         -Verbose
# }
