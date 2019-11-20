#!/usr/bin/env pwsh

<#
.PARAMETER LocalToo
    Allows destruction of region A without blowing out the SSH Key for region B

.TODO
    Backup SSH Key? 🤔😬
#>

[CmdletBinding()]
Param(
    [Parameter()]
    [ValidateSet([ValidBtdPositionGenerator])]
    [string]
    $Position = 'Default',
    [Parameter()]
    [switch]
    $LocalToo
)

./destroy/cluster $Position
./destroy/keypair $Position
./destroy/loadbalancer $Position
./destroy/network $Position
if($LocalToo){./destroy/local}
