function Register-CrdbEnvVars {
<#
.DESCRIPTION
    Read local conf/actual and (re)export utility values to common varible names in global scope 
#>
    [CmdletBinding()]
    param (
        [Parameter()]
        # TODO: https://vexx32.github.io/2018/11/29/Dynamic-ValidateSet/
        [ValidateSet('Default','Remote1')]
        [string]
        $Position = 'Default'
    )

    $script:ec2 = Get-Content "./conf/actual/Cluster.$Position.json" | ConvertFrom-Json
    $script:jb = Get-Content  "./conf/actual/JumpBox.$Position.json" -ErrorAction SilentlyContinue | ConvertFrom-Json

    New-Variable -Scope Global -Name identFile -Value (Resolve-Path "./conf/secret/$($btd_Defaults.KeyPair.Name).pem") -Verbose -Force
    New-Variable -Scope Global -Name certsDir -Value (Resolve-Path "$($btd_Defaults.CertsDirectory)/certs") -Verbose -Force

    foreach($node in @($ec2.Instances + $jb.Instances)){
        $script:IP = $node.PublicIpAddress
        $script:hostname = ($node.Tags | Where-Object key -eq name).Value
    
        if((Get-EC2Instance -Region $btd_VPC.$Position.Region).RunningInstance.InstanceId -contains $node.InstanceId) {
            New-Variable -Value $node -Name $hostname -Scope Global -Force
            Write-Host "Variable $hostname created" -ForegroundColor Green
        }
    }    
}
