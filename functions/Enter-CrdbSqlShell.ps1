function Enter-CrdbSqlShell {
    [CmdletBinding()]
    param (
        [Parameter()]
        [String]
        $SqlHost = ((Get-Content ./conf/actual/Cluster.json | ConvertFrom-Json).Instances[0].PublicIpAddress),
        [Parameter()]
        [String]
        $UserName = 'root',
        [Parameter()]
        [String]
        $certsDir = (Resolve-Path "$($btd_Defaults.CertsDirectory)/certs")
    )

    cockroach sql --certs-dir=$certsDir --host=$SqlHost
}