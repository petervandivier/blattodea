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
$script:jh = Get-Content ./conf/actual/JumpBox.json | ConvertFrom-Json

if(-not $NoLaunch){Enter-CrdbAdminUi}

New-Variable -Scope Global -Name identFile -Value (Resolve-Path "./conf/secret/$($btd_Defaults.KeyPair.Name).pem") -Verbose -Force
New-Variable -Scope Global -Name certsDir -Value (Resolve-Path "$($btd_Defaults.CertsDirectory)/certs") -Verbose -Force

foreach($user in $btd_Users){
    $cmd = "CREATE USER $($user.username) WITH PASSWORD '$($user.password)';"
    cockroach sql --certs-dir=$certsDir --host="$IP" --execute="$cmd"
}

$cmd = "SET CLUSTER SETTING server.remote_debugging.mode = 'any';"
cockroach sql --certs-dir=$certsDir --host="$IP" --execute="$cmd"

foreach($node in @($ec2.Instances + $jh.Instances)){
    $script:IP = $node.PublicIpAddress
    $script:hostname = ($node.Tags | Where-Object key -eq name).Value

    New-Variable -Value $node -Name $hostname -Scope Global -Force
    Write-Host "Variable $hostname created" -ForegroundColor Green
}

Write-Host 'cockroach sql --certs-dir=$certsDir --host="$($crdb1.PublicIpAddress)"' -ForegroundColor Cyan
Write-Host 'dsh -i $identFile centos@"$($crdb1.PublicIpAddress)"' -ForegroundColor Cyan
