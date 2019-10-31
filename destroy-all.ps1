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
    [switch]
    $LocalToo
)

./destroy/cluster
./destroy/loadbalancer
./destroy/network
if($LocalToo){./destroy/local}
