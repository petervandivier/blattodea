function Resolve-BtdPeeringConfiguration {
    [CmdletBinding()]
    param (
        # [Parameter()]
        # [ValidateSet([ValidBtdPositionGenerator])]
        # [string]
        # $Position = 'Default',

        [Parameter()]
        $VPCConfiguration = ($btd_VPC | ConvertTo-Json -Depth 10 | ConvertFrom-Json -Depth 10)
    )

<#
    $pcx = Get-ChildItem "./conf/actual/pcx*$Position*.json" | ForEach-Object {
        Get-Content $_.FullName -Raw
    } | Select-Object -Unique | ForEach-Object {
        ($PSItem | ConvertFrom-Json).VpcPeeringConnectionId
    } | Select-Object -Unique

    $peers = Get-EC2VpcPeeringConnection `
        -Filter @{Name='vpc-peering-connection-id';Value=$pcx} `
        -Region $btd_VPC.$Position.Region
#>

    foreach($pos in ($VPCConfiguration.PSObject.Properties.Name)){
        $vpc = Get-Content "./conf/actual/VPC.$pos.json" -ErrorAction SilentlyContinue | ConvertFrom-Json
        $vpc = Get-EC2Vpc -Filter @{Name='vpc-id';Value=$vpc.VpcId} -Region $btd_VPC.$pos.Region

        $vpcExists = if($vpc){$true}else{$false}

        $VPCConfiguration.$pos | Add-Member -Type NoteProperty -Name Exists -Value $vpcExists
    }

    $VPCConfiguration
}
