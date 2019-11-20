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

$ec2 = (Get-Content "./conf/actual/Cluster.$Position.json" | ConvertFrom-Json).Instances
# TODO: handle jumpbox better
$jb  = (Get-Content "./conf/actual/JumpBox.$Position.json" -ErrorAction SilentlyContinue | ConvertFrom-Json).Instances

# Get-EC2Instance barfs on not-found InstancesIds, hence this handling
$getEc2 = [scriptblock]{ Get-EC2Instance -Filter @{Name='instance-id';Value=@($ec2.InstanceId + $jb.InstanceId)}}

& $getEc2 | Remove-EC2Instance -Confirm:$false 

if(& $getEc2){
    while((& $getEc2).Instances.State.Name -ne 'terminated'){
        Write-Host "Awaiting termination of all EC2 instances. Sleeping 10..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
    } 
}
Write-Host "$(Get-Date) : all nodes report state 'terminated'" -ForegroundColor Blue

Set-DefaultAWSRegion $PopRegion
