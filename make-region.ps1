#!/usr/bin/env pwsh
#Requires -Module blattodea

[CmdletBinding()]
Param(
    [Parameter()]
    [ValidateSet([ValidBtdPositionGenerator])]
    [string]
    $Position = 'Default',
    [Parameter()]
    [switch]
    $JumpBox
)

./make/vpc $Position
./make/subnet $Position
./make/securitygroup $Position
./make/keypair $Position
./make/cluster $Position
if($JumpBox){./make/jumpbox} 
./make/loadbalancer $Position -JumpBox:$JumpBox
if($Position -ne 'Default'){./make/peering}
./make/certs $Position -JumpBox:$JumpBox
# Build-CrdbCerts also inits. TODO: tidy
if($Position -eq 'Default'){
    ./make/initdb
    ./make/postdeploy
}
