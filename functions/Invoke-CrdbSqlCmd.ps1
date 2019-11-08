function Invoke-CrdbSqlCmd {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true,Position=0)]
        [String]
        $Command,
        [Parameter()]
        [String]
        $SqlHost = ((Get-Content "./conf/actual/Cluster.Default.json" | ConvertFrom-Json).Instances[0].PublicIpAddress),
        [Parameter()]
        [Alias('dbname')]
        [String]
        $Database = 'defaultdb',
        [Parameter()]
        [String]
        $UserName = 'root',
        [Parameter()]
        [String]
        $certsDir = (Resolve-Path "$($btd_Defaults.CertsDirectory)/certs")
    )

    Write-Output $Command | cockroach sql --certs-dir=$certsDir --host=$SqlHost --database=$Database
}

New-Alias -Name 'icr' -Value 'Invoke-CrdbSqlCmd' -Force
