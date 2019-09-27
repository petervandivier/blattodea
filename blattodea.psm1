#!/usr/bin/env pwsh

Set-Location $PSScriptRoot

Get-ChildItem -Path ./functions | ForEach-Object {
    . $PSItem.FullName 
}

. ./utils.ps1
