#!/usr/bin/env pwsh
#Requires -Module blattodea

$script:ec2 = Get-Content ./conf/actual/Cluster.json | ConvertFrom-Json
$script:IP = $ec2.Instances[0].PublicIPAddress
$script:jh = Get-Content ./conf/actual/JumpBox.json | ConvertFrom-Json

New-Variable -Name identFile -Value (Resolve-Path "./conf/secret/$($btd_Defaults.KeyPair.Name).pem") -Verbose
New-Variable -Name certsDir -Value (Resolve-Path "$($btd_Defaults.CertsDirectory)/certs") -Verbose

foreach($user in $btd_Users){
    $cmd = "CREATE USER $($user.username) WITH PASSWORD '$($user.password)';"    
    cockroach sql --certs-dir=$certsDir --host="$IP" --execute="$cmd"
}

foreach($node in @($ec2.Instances + $jh.Instances)){
    $script:IP = $node.PublicIpAddress
    $script:hostname = ($node.Tags | Where-Object key -eq name).Value
    dsh -i $identFile centos@$IP "sudo hostnamectl set-hostname $hostname"

    New-Variable -Value $node -Name $hostname -Scope Global -Force
    Write-Host "Variable $hostname created" -ForegroundColor Green
}

Write-Host 'cockroach sql --certs-dir=$certsDir --host="$($crdb1.PublicIpAddress)"' -ForegroundColor Cyan
Write-Host 'dsh -i $identFile centos@"$($crdb1.PublicIpAddress)"' -ForegroundColor Cyan

# $browser = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' "https://$IP`:8080"
# TODO: ¿Start-Process $browser -Async?
open -a "Firefox" "https://$IP`:8080" 
