#!/usr/bin/env pwsh
#Requires -Module blattodea

$script:ec2 = Get-Content ./conf/actual/Cluster.json | ConvertFrom-Json

foreach($key in ($ec2.Instances.KeyName | Select-Object -Unique)){
    Remove-Item -Path "./conf/secret/$key.pem"
}

Remove-Item $btd_Defaults.CertsDirectory -Recurse -Force -Confirm:$false
