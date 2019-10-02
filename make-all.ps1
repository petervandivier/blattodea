#!/usr/bin/env pwsh
#Requires -Module blattodea

. make/cluster
. make/loadbalancer
. make/certs
. make/initdb

$script:IP = (Get-Content ./conf/actual/cluster.json | ConvertFrom-Json)[0].Instances.PublicIPAddress
# $browser = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' "https://$IP`:8080"
# TODO: open async
# Start-Process $browser "https://$IP`:8080"
open -a "Google Chrome" "https://$IP`:8080" 

$script:ec2 = Get-Content ./conf/actual/Cluster.json | ConvertFrom-Json

Write-Host "CREATE USER $(whoami) WITH PASSWORD 'cockroach';" -ForegroundColor Blue
Write-Host "cockroach sql --certs-dir=$(Resolve-Path $btd_Defaults.CertsDirectory) --host=($ec2.Instances[0].PublicIPAddress)" -ForegroundColor Blue
