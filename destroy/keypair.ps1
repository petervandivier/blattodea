#!/usr/bin/env pwsh

[CmdletBinding()]
param (
    [Parameter()]
    # TODO: https://vexx32.github.io/2018/11/29/Dynamic-ValidateSet/
    [ValidateSet([ValidBtdPositionGenerator])]
    [string]
    $Position = 'Default'
)

Remove-EC2KeyPair -KeyName $btd_Defaults.KeyPair.Name -Confirm:$false -Region $btd_VPC.$Position.Region
