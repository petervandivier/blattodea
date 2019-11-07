#!/usr/bin/env pwsh
#Requires -Module blattodea

# TODO: fix the load balancer entirely
#   none of the targets have actually registered healthy yet afaik
# how does having one load-balancer per-region actually help?
#   do the app hosts target the nearest LB? 🤔🤷‍

[CmdletBinding()]
param (
    [Parameter()]
    [ValidateSet([ValidBtdPositionGenerator])]
    [string]
    $Position = 'Default',
    [Parameter()]
    [switch]
    $JumpBox
)

$PopRegion = $StoredAWSRegion
$PushRegion = $btd_VPC.$Position.Region
Set-DefaultAWSRegion $PushRegion

$vpc = Get-Content "./conf/actual/VPC.$Position.json"     | ConvertFrom-Json
$sn  = Get-Content "./conf/actual/Subnets.$Position.json" | ConvertFrom-Json
$ec2 = Get-Content "./conf/actual/Cluster.$Position.json" | ConvertFrom-Json

$LoadBalancer = @{
    IpAddressType = $btd_LoadBalancer.IpAddressType 
    Name = $btd_LoadBalancer.Name 
    Scheme = $btd_LoadBalancer.Scheme
    Subnet = $sn.SubnetId 
    Tags = $btd_CommonTags.ToTagArray()
    Type = $btd_LoadBalancer.Type    
}

$elb = New-ELB2LoadBalancer @LoadBalancer

$TargetGroup = @{
    HealthCheckPath = $btd_TargetGroup.HealthCheckPath
    HealthCheckPort = $btd_TargetGroup.HealthCheckPort
    HealthCheckProtocol = $btd_TargetGroup.HealthCheckProtocol
    Port = $btd_TargetGroup.Port
    Protocol = $btd_TargetGroup.Protocol
    Name = $btd_TargetGroup.Name
    TargetType = $btd_TargetGroup.TargetType
    VpcId = $vpc.VpcId
}

$tg = New-ELB2TargetGroup @TargetGroup 

foreach($id in $ec2.Instances.InstanceId){
    Register-ELB2Target -TargetGroupArn $tg.TargetGroupArn -Target @{Id=$id;Port=26257}
}

$Listener = @{
    LoadBalancerArn = $elb.LoadBalancerArn 
    Protocol = $btd_Listener.Protocol
    Port = $btd_Listener.Port
    DefaultActions = @{
        TargetGroupArn = $tg.TargetGroupArn
        Type = 'forward' 
    }
}

$lbl = New-ELB2Listener @Listener

# TODO: IAM role prereq (need perms)
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html#create-iam-role-console
# ¿TODO: re-bundle EC2 instance to AMI?

$elb | ConvertTo-Json -Depth 5 | Set-Content "./conf/actual/LoadBalancer.$Position.json" -Force
$tg  | ConvertTo-Json -Depth 5 | Set-Content "./conf/actual/TargetGroup.$Position.json"  -Force
$lbl | ConvertTo-Json -Depth 5 | Set-Content "./conf/actual/Listener.$Position.json"     -Force

Set-DefaultAWSRegion $PopRegion
