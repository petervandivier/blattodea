#!/usr/bin/env pwsh

Set-Location $PSScriptRoot

. ./classes.ps1

Get-ChildItem -Path ./functions | ForEach-Object {
    . $PSItem.FullName 
}

. ./utils.ps1
