#!/usr/bin/env pwsh
#Requires -Module blattodea

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

$acceptVpc  = Get-Content "./conf/actual/VPC.$acceptPosition.json"  | ConvertFrom-Json 
$requestVpc = Get-Content "./conf/actual/VPC.$requestPosition.json" | ConvertFrom-Json 

$peerSplat = @{
    Region      = $btd_VPC.$requestPosition.Region
    VpcId       = $requestVpc.VpcId
    PeerVpcId   = $acceptVpc.VpcId
    PeerOwnerId = $acceptVpc.OwnerId
    PeerRegion  = $btd_VPC.$acceptPosition.Region
}
$peer = New-EC2VpcPeeringConnection @peerSplat -Verbose 
# TODO: tag:common & tag:name requester & accepter

# TODO: await() this shit properly
Start-Sleep -Seconds 5 

Approve-EC2VpcPeeringConnection `
    -VpcPeeringConnectionId $peer.VpcPeeringConnectionId `
    -Region $btd_VPC.$acceptPosition.Region `
    -Verbose

Start-Sleep -Seconds 5 

$peer = Get-EC2VpcPeeringConnection `
    -VpcPeeringConnectionId $peer.VpcPeeringConnectionId `
    -Region $btd_VPC.$requestPosition.Region

$acceptRtb  = Get-Content "./conf/actual/RTB.$acceptPosition.json"  | ConvertFrom-Json
$requestRtb = Get-Content "./conf/actual/RTB.$requestPosition.json" | ConvertFrom-Json

New-EC2Route `
    -RouteTableId $acceptRtb.RouteTableId `
    -GatewayId $peer.VpcPeeringConnectionId `
    -DestinationCidrBlock $peer.RequesterVpcInfo.CidrBlock `
    -Region $peer.AccepterVpcInfo.Region |
        Out-Null

New-EC2Route `
    -RouteTableId $requestRtb.RouteTableId `
    -GatewayId $peer.VpcPeeringConnectionId `
    -DestinationCidrBlock $peer.AccepterVpcInfo.CidrBlock `
    -Region $peer.RequestVpcInfo.Region |
        Out-Null

# i _think_ the rtb updates are shown on the pcx object? should prob check at some point...
$peer | ConvertTo-Json -Depth 5 | Set-Content "./conf/actual/pcx-$acceptPosition-$requestPosition.json" -Force
New-Item `
    -ItemType SymbolicLink `
    -Path "./conf/actual/" `
    -Name "pcx-$requestPosition-$acceptPosition.json" `
    -Value "pcx-$acceptPosition-$requestPosition.json" `
    -Force

$script:acceptSg  = Get-Content "./conf/actual/SecurityGroup.$acceptPosition.json"  | ConvertFrom-Json
$script:requestSg = Get-Content "./conf/actual/SecurityGroup.$requestPosition.json" | ConvertFrom-Json

$acceptSg  = Get-EC2SecurityGroup -GroupId $acceptSg.GroupId  -Region $peer.AccepterVpcInfo.Region
$requestSg = Get-EC2SecurityGroup -GroupId $requestSg.GroupId -Region $peer.RequesterVpcInfo.Region

# Need to troubleshoot re-grant on destroy/peering for port 80 if we want to grant it here
# just excluding port 80 from peering for the moment
foreach($port in @(8080,26257,22)){
    $perm = [Amazon.EC2.Model.IpPermission]@{
        IpProtocol = 'tcp'
        FromPort = $port
        ToPort = $port
        IpRange = $peer.RequesterVpcInfo.CidrBlock
# TODO: Add descriptions
    }

    Grant-EC2SecurityGroupIngress `
        -GroupId $acceptSg.GroupId `
        -IpPermission $perm `
        -Region $peer.AccepterVpcInfo.Region
}
# TODO: allow ping

foreach($port in @(8080,26257,22)){
    $perm = [Amazon.EC2.Model.IpPermission]@{
        IpProtocol = 'tcp'
        FromPort = $port
        ToPort = $port
        IpRange = $peer.AccepterVpcInfo.CidrBlock
# TODO: Add descriptions
    }

    Grant-EC2SecurityGroupIngress `
        -GroupId $requestSg.GroupId `
        -IpPermission $perm `
        -Region $peer.RequesterVpcInfo.Region
}
# TODO: allow ping
