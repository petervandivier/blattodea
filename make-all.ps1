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
Write-Host "cockroach sql --certs-dir=$(Resolve-Path $btd_Defaults.CertsDirectory)/certs --host=$IP" -ForegroundColor Blue
