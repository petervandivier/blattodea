#!/usr/bin/env pwsh
#Requires -Module blattodea

[CmdletBinding()]
param (
    [Parameter()]
    [switch]
    $NoLaunch
)

$script:ec2 = Get-Content "./conf/actual/Cluster.Default.json" | ConvertFrom-Json
$script:IP = $ec2.Instances[0].PublicIPAddress

if(-not $NoLaunch){Enter-CrdbAdminUi}

Register-CrdbEnvVars

Get-ChildItem "./templates/schema/*/*.schema.sql" -Recurse | 
  Where-Object Directory -NotLike "*example*" | 
  ForEach-Object {
    $db = $_.BaseName.Split('.')[0]
    Write-Output "create database $db;" | Invoke-CrdbSqlCmd -certsDir $certsDir -SqlHost $IP
    Get-Content $_.FullName -Raw | Invoke-CrdbSqlCmd -certsDir $certsDir -SqlHost $IP -Database $db
}

foreach($user in $btd_Users){
    $cmd = "CREATE USER $($user.username) WITH PASSWORD '$($user.password)';"
    cockroach sql --certs-dir=$certsDir --host="$IP" --execute="$cmd"
}

$cmd = "SET CLUSTER SETTING server.remote_debugging.mode = 'any';"
cockroach sql --certs-dir=$certsDir --host="$IP" --execute="$cmd"

Write-Host 'cockroach sql --certs-dir=$certsDir --host="$($crdb01.PublicIpAddress)"' -ForegroundColor Cyan
Write-Host 'dsh -i $identFile centos@"$($crdb01.PublicIpAddress)"' -ForegroundColor Cyan
