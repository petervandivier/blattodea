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

if($Position -ne 'Default'){
# https://docs.aws.amazon.com/powershell/latest/reference/items/Import-EC2KeyPair.html
# fingerprint will be different from initial keypair 🤷‍♂️ still works
    $script:kp = Get-Content "./conf/actual/KeyPair.json" | ConvertFrom-Json
    $identFile = Resolve-Path "./conf/secret/$($kp.KeyName).pem"
    $publickey = openssl rsa -in $identFile -pubout
    $publickey | Set-Content "./conf/secret/$($kp.KeyName).pub" -Force
    $mPKCS8 = ssh-keygen -f "./conf/secret/$($kp.KeyName).pub" -i -mPKCS8
    $pkbase64 = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($mPKCS8))

# TODO: error handle import same as creation
    Import-EC2KeyPair -KeyName $kp.KeyName -PublicKeyMaterial $pkbase64 -Region $btd_VPC.$Position.Region

    return
}

if((Get-EC2KeyPair).KeyName -contains $btd_Defaults.KeyPair.Name){
    $btd_Defaults.KeyPair.Name = "$($btd_Defaults.KeyPair.Name)_$(Get-Random)"
    Write-Warning "Duplicate Key Pair Name detected."
    Write-Warning "Hot-swapping KeyName in conf. New name is '$($btd_Defaults.KeyPair.Name)'."
}

$kp = New-EC2KeyPair -KeyName $btd_Defaults.KeyPair.Name -Region $btd_VPC.$Position.Region

$sshKey = "conf/secret/$($kp.KeyName).pem"

$kp.KeyMaterial | Set-Content $sshKey -Force
$kp | Select-Object KeyFingerprint, KeyName | ConvertTo-Json | Set-Content ./conf/actual/KeyPair.json -Force

chmod 0600 $sshKey
