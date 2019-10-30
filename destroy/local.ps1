#!/usr/bin/env pwsh
#Requires -Module blattodea

[CmdletBinding()]
param (
    [Parameter()]
    # TODO: https://vexx32.github.io/2018/11/29/Dynamic-ValidateSet/
    [ValidateSet('Default','Remote1')]
    [string]
    $Position = 'Default'
)

$script:ec2 = Get-Content ./conf/actual/Cluster.json | ConvertFrom-Json

foreach($key in ($ec2.Instances.KeyName | Select-Object -Unique)){
    Remove-Item -Path "./conf/secret/$key.pem"
    Remove-Item -Path "./conf/secret/$key.pub"
}

Remove-Item $btd_Defaults.CertsDirectory -Recurse -Force
