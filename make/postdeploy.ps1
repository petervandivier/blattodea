#!/usr/bin/env pwsh
#Requires -Module blattodea

[CmdletBinding()]
param (
    [Parameter()]
    [switch]
    $NoLaunch
)

$script:ec2 = Get-Content ./conf/actual/Cluster.json | ConvertFrom-Json
$script:IP = $ec2.Instances[0].PublicIPAddress

if(-not $NoLaunch){Enter-CrdbAdminUi}

Register-CrdbEnvVars

foreach($user in $btd_Users){
    $cmd = "CREATE USER $($user.username) WITH PASSWORD '$($user.password)';"
    cockroach sql --certs-dir=$certsDir --host="$IP" --execute="$cmd"
}

$cmd = "SET CLUSTER SETTING server.remote_debugging.mode = 'any';"
cockroach sql --certs-dir=$certsDir --host="$IP" --execute="$cmd"

Write-Host 'cockroach sql --certs-dir=$certsDir --host="$($crdb01.PublicIpAddress)"' -ForegroundColor Cyan
Write-Host 'dsh -i $identFile centos@"$($crdb01.PublicIpAddress)"' -ForegroundColor Cyan
