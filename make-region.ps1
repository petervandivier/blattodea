#!/usr/bin/env pwsh
#Requires -Module blattodea

[CmdletBinding()]
Param(
    [Parameter()]
    # TODO: https://vexx32.github.io/2018/11/29/Dynamic-ValidateSet/
    [ValidateSet('Default','Remote1')]
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
