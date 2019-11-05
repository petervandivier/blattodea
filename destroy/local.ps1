#!/usr/bin/env pwsh
#Requires -Module blattodea

$script:nodes = (Get-ChildItem "./conf/actual/Cluster.*.json" | Get-Content -Raw | ForEach-Object{ ConvertFrom-Json $_}).Instances

foreach($key in ($nodes.KeyName | Select-Object -Unique)){
    Remove-Item -Path "./conf/secret/$key.pem"
    Remove-Item -Path "./conf/secret/$key.pub" -ErrorAction SilentlyContinue
}

Remove-Item $btd_Defaults.CertsDirectory -Recurse -Force 
