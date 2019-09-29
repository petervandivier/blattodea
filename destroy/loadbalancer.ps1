#!/usr/bin/env pwsh

$lbl = Get-Content ./conf/actual/Listener.json     | ConvertFrom-Json
$tg  = Get-Content ./conf/actual/TargetGroup.json  | ConvertFrom-Json
$elb = Get-Content ./conf/actual/LoadBalancer.json | ConvertFrom-Json

Remove-ELB2Listener -ListenerArn $lbl.ListenerArn -Confirm:$false

Remove-ELB2TargetGroup -TargetGroupArn $tg.TargetGroupArn -Confirm:$false

Remove-ELB2LoadBalancer -LoadBalancerArn $elb.LoadBalancerArn -Confirm:$false
