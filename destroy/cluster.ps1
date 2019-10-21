#!/usr/bin/env pwsh

$ec2 = (Get-Content ./conf/actual/Cluster.json | ConvertFrom-Json).Instances
$jh  = (Get-Content ./conf/actual/JumpBox.json | ConvertFrom-Json).Instances

$getEc2 = [scriptblock]{Get-EC2Instance @($ec2.InstanceId + $jh.InstanceId)}

& $getEc2 | Remove-EC2Instance -Confirm:$false 

if(& $getEc2){
    while((& $getEc2).Instances.State.Name -ne 'terminated'){
        Write-Host "Awaiting termination of all EC2 instances. Sleeping 10..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
    } 
}
Write-Host "$(Get-Date) : all nodes report state 'terminated'" -ForegroundColor Blue

Remove-EC2KeyPair -KeyName $btd_Defaults.KeyPair.Name -Confirm:$false 
