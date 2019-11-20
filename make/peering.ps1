#!/usr/bin/env pwsh
#Requires -Module blattodea

[CmdletBinding()]
param (
    [Parameter()]
    [ValidateSet([ValidBtdPositionGenerator])]
    [string]
    $acceptPosition  = 'Remote1',

    [Parameter()]
    [ValidateSet([ValidBtdPositionGenerator])]
    [string]
    $requestPosition = 'Default'
)

Initialize-EC2VPCPeeringConfiguration `
    -AcceptPosition $acceptPosition `
    -RequestPosition $requestPosition 
