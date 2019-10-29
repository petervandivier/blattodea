function Register-CrdbEnvVars {
<#
.DESCRIPTION
    Read local conf/actual and (re)export utility values to common varible names in global scope 
#>
    $script:ec2 = Get-Content ./conf/actual/Cluster.json | ConvertFrom-Json
    $script:jh = Get-Content ./conf/actual/JumpBox.json | ConvertFrom-Json

    New-Variable -Scope Global -Name identFile -Value (Resolve-Path "./conf/secret/$($btd_Defaults.KeyPair.Name).pem") -Verbose -Force
    New-Variable -Scope Global -Name certsDir -Value (Resolve-Path "$($btd_Defaults.CertsDirectory)/certs") -Verbose -Force

    foreach($node in @($ec2.Instances + $jh.Instances)){
        $script:IP = $node.PublicIpAddress
        $script:hostname = ($node.Tags | Where-Object key -eq name).Value
    
        New-Variable -Value $node -Name $hostname -Scope Global -Force
        Write-Host "Variable $hostname created" -ForegroundColor Green
    }    
}
