#!/usr/bin/env pwsh

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

$lbl = Get-Content "./conf/actual/Listener.$Position.json"     | ConvertFrom-Json
$tg  = Get-Content "./conf/actual/TargetGroup.$Position.json"  | ConvertFrom-Json
$elb = Get-Content "./conf/actual/LoadBalancer.$Position.json" | ConvertFrom-Json

Remove-ELB2Listener -ListenerArn $lbl.ListenerArn -Confirm:$false

Remove-ELB2TargetGroup -TargetGroupArn $tg.TargetGroupArn -Confirm:$false

Remove-ELB2LoadBalancer -LoadBalancerArn $elb.LoadBalancerArn -Confirm:$false

Set-DefaultAWSRegion $PopRegion
