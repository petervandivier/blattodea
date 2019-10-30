#!/usr/bin/env pwsh

[CmdletBinding()]
param (
    [Parameter()]
    # TODO: https://vexx32.github.io/2018/11/29/Dynamic-ValidateSet/
    [ValidateSet('Default','Remote1')]
    [string]
    $Position = 'Default'
)

$PopRegion = (Get-DefaultAWSRegion).Region
$PushRegion = $btd_VPC.$Position.Region
Set-DefaultAWSRegion $PushRegion

$ec2 = (Get-Content "./conf/actual/Cluster.$Position.json" | ConvertFrom-Json).Instances
# TODO: handle jumpbox better
if($Position -eq 'Default'){$jh  = (Get-Content "./conf/actual/JumpBox.json" | ConvertFrom-Json).Instances}

$getEc2 = [scriptblock]{Get-EC2Instance @($ec2.InstanceId + $jh.InstanceId)}

& $getEc2 | Remove-EC2Instance -Confirm:$false 

if(& $getEc2){
    while((& $getEc2).Instances.State.Name -ne 'terminated'){
        Write-Host "Awaiting termination of all EC2 instances. Sleeping 10..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
    } 
}
Write-Host "$(Get-Date) : all nodes report state 'terminated'" -ForegroundColor Blue

# TODO: ¿segregate Remove-EC2KeyPair for better make/destroy testing?
Remove-EC2KeyPair -KeyName $btd_Defaults.KeyPair.Name -Confirm:$false 

Set-DefaultAWSRegion $PopRegion
