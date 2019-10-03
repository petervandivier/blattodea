#!/usr/bin/env pwsh
#Requires -Module blattodea

if((Get-EC2KeyPair).KeyName -contains $btd_Defaults.KeyPair.Name){
    $btd_Defaults.KeyPair.Name = "$($btd_Defaults.KeyPair.Name)_$(Get-Random)"
    Write-Warning "Duplicate Key Pair Name detected."
    Write-Warning "Hot-swapping KeyName in conf. New name is '$($btd_Defaults.KeyPair.Name)'."
}

$kp = New-EC2KeyPair -KeyName $btd_Defaults.KeyPair.Name

$sshKey = "conf/secret/$($kp.KeyName).pem"

$kp.KeyMaterial | Set-Content $sshKey -Force
$kp | Select-Object KeyFingerprint, KeyName | ConvertTo-Json | Set-Content ./conf/actual/KeyPair.json -Force

chmod 0600 $sshKey
