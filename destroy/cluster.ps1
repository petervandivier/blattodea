#!/usr/bin/env pwsh

[CmdletBinding()]
param (
    [Parameter()]
    # TODO: https://vexx32.github.io/2018/11/29/Dynamic-ValidateSet/
    [ValidateSet('Default','Remote1')]
    [string]
    $Position = 'Default'
)

$PopRegion = $StoredAWSRegion
$PushRegion = $btd_VPC.$Position.Region
Set-DefaultAWSRegion $PushRegion

$ec2 = (Get-Content "./conf/actual/Cluster.$Position.json" | ConvertFrom-Json).Instances
# TODO: handle jumpbox better
$jb  = (Get-Content "./conf/actual/JumpBox.$Position.json" -ErrorAction SilentlyContinue | ConvertFrom-Json).Instances

# Get-EC2Instance barfs on not-found InstancesIds, hence this handling
$getEc2 = [scriptblock]{ (@($ec2.InstanceId + $jb.InstanceId) | Test-EC2Instance | Where-Object Exists).InstanceId | Get-EC2Instance }

if((& $getEc2).Count -gt ($ec2.Count + $jb.Count)){
    Write-Error "Looks like you're fixin' to terminate someone else's instances, maybe chill with that."
    return;
}

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
