#!/usr/bin/env pwsh
#Requires -Module blattodea

# this will only work for two-region peering
# need to gamify from->to decision logic for 3+ regions
$acceptPosition  = 'Remote1'
$requestPosition = 'Default'

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

Start-Sleep -Seconds 2 -Verbose

Approve-EC2VpcPeeringConnection -VpcPeeringConnectionId $peer.VpcPeeringConnectionId -Region $btd_VPC.$acceptPosition.Region -Verbose

$peer = Get-EC2VpcPeeringConnection -VpcPeeringConnectionId $peer.VpcPeeringConnectionId

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
$peer | ConvertTo-Json -Depth 5 | Set-Content "./conf/actual/Peering.json" -Force

$script:acceptSg  = Get-Content "./conf/actual/SecurityGroup.$acceptPosition.json"  | ConvertFrom-Json
$script:requestSg = Get-Content "./conf/actual/SecurityGroup.$requestPosition.json" | ConvertFrom-Json

$acceptSg  = Get-EC2SecurityGroup -GroupId $acceptSg.GroupId  -Region $peer.AccepterVpcInfo.Region
$requestSg = Get-EC2SecurityGroup -GroupId $requestSg.GroupId -Region $peer.RequesterVpcInfo.Region

foreach($port in @(80,8080,26257,22)){
    $perm = [Amazon.EC2.Model.IpPermission]@{
        IpProtocol = 'tcp'
        FromPort = $port
        ToPort = $port
        IpRange = $peer.RequesterVpcInfo.CidrBlock
# TODO: Add descriptions
    }

    Grant-EC2SecurityGroupIngress -GroupId $acceptSg.GroupId  -IpPermission $perm -Region $peer.AccepterVpcInfo.Region
}
# TODO: allow ping

foreach($port in @(80,8080,26257,22)){
    $perm = [Amazon.EC2.Model.IpPermission]@{
        IpProtocol = 'tcp'
        FromPort = $port
        ToPort = $port
        IpRange = $peer.AccepterVpcInfo.CidrBlock
# TODO: Add descriptions
    }
    Grant-EC2SecurityGroupIngress -GroupId $requestSg.GroupId -IpPermission $perm -Region $peer.RequesterVpcInfo.Region
}
# TODO: allow ping
