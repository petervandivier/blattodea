#!/usr/bin/env pwsh
#Requires -Module AWSPowerShell

Get-ChildItem -Path ./conf/target/*.json | ForEach-Object {
    $configuration = @{
        Name = "btd_$($_.BaseName)"
        Value = (Get-Content -LiteralPath $_.FullName | ConvertFrom-Json)
        Force = $true
        Scope = 'Global'
    }
    New-Variable @configuration
}

Set-DefaultAWSRegion -Region $btd_Defaults.DefaultRegion -Scope Global

# .ToArray() feels presumptious, that method name is ubiquitous, right?? or am i free to use that name?
Add-Member -InputObject $btd_CommonTags `
           -Name ToTagArray `
           -MemberType ScriptMethod `
           -Value {
                $btd_CommonTags.PSObject.Properties | 
                ForEach-Object {
                   [pscustomobject]@{Key=$_.Name;Value=$_.Value}}
                } 

Add-Member -InputObject $btd_IpPermissions `
    -Name 'SetSecurityGroup' `
    -MemberType 'ScriptMethod' `
    -Value {
        Param(
            [string]$SecurityGroupId
        )
        ($this | Where-Object UserIdGroupPairs -ne $null).UserIdGroupPairs | ForEach-Object {
            $_.GroupId = $SecurityGroupId
        }  
    }

Add-Member -InputObject $btd_IpPermissions `
    -Name 'SetMyIp' `
    -MemberType 'ScriptMethod' `
    -Value {
        $my_ip = (Invoke-WebRequest -Uri "http://ifconfig.me/ip").Content 

        ($this | Where-Object IpV4Ranges -ne $null).IpV4Ranges | ForEach-Object {
            $_.CidrIp = "$my_ip/32"
            $_.Description = ($_.Description -f "$(whoami)@$(hostname -s)")
        }  
    }
