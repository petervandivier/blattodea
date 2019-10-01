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
