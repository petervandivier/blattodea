#!/usr/bin/env pwsh
#Requires -Module blattodea

[CmdletBinding()]
Param(
    [Parameter()]
    [switch]
    $JumpBox
)

./make/vpc
./make/subnet
./make/securitygroup
./make/keypair
./make/cluster
if($JumpBox){./make/jumpbox}
./make/loadbalancer
./make/certs
./make/initdb
./make/postdeploy
