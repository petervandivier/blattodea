function Find-AWSRegion {
<#
.DESCRIPTION
    Describe the region for a given AZ
#>
    [CmdletBinding()]
    param (
        [Parameter()]
        [Alias('AZ')]
        [string]
        $AvailabilityZone
    )

    $Region = [regex]::match($AvailabilityZone,'^(.*).$').Groups[1].Value

    Get-AWSRegion $Region
}