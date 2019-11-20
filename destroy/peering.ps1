#!/usr/bin/env pwsh

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

Remove-EC2VpcPeeringConfiguration `
    -AcceptPosition $acceptPosition `
    -RequestPosition $requestPosition
