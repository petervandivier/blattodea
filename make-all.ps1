#!/usr/bin/env pwsh
#Requires -Module blattodea

. make/vpc
. make/subnet
. make/securitygroup
. make/keypair
. make/cluster
. make/loadbalancer
. make/certs
. make/initdb

$script:ec2 = Get-Content ./conf/actual/Cluster.json | ConvertFrom-Json
$script:IP = $ec2.Instances[0].PublicIPAddress
# $browser = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' "https://$IP`:8080"
# TODO: open async
# Start-Process $browser "https://$IP`:8080"
open -a "Firefox" "https://$IP`:8080" 

Write-Host "CREATE USER $(whoami) WITH PASSWORD 'cockroach';" -ForegroundColor Blue
Write-Host '$identFile=(Resolve-Path "./conf/secret/$($btd_Defaults.KeyPair.Name).pem")' -ForegroundColor Blue
Write-Host '$certsDir="$(Resolve-Path $btd_Defaults.CertsDirectory)/certs"' -ForegroundColor Blue
Write-Host '(gc ./conf/actual/Cluster.json | Cfj).instances | % { New-Variable -Value $_ -Name ($_.Tags | where key -eq name).Value}' -ForegroundColor Blue
Write-Host 'cockroach sql --certs-dir=$certsDir --host="$($crdb1.PublicIpAddress)"' -ForegroundColor Blue
Write-Host 'dsh -i $identFile centos@"$($crdb1.PublicIpAddress)"' -ForegroundColor Blue
Write-Host '(gc ./conf/actual/Cluster.json | Cfj).instances | % {dsh -i $identFile centos@"$($_.PublicIpAddress)" "sudo hostnamectl set-hostname $(($_.Tags | where key -eq name).Value)"}' -ForegroundColor Blue
