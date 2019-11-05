function Reset-CrdbAdminIngress {
<#
.DESCRIPTION
    one-liner for re-granting access to yourself when you change wifi networks

.TODO
    security-group access is bound to the same [Amazon.EC2.Model.IpPermission] object as personal IP access
    does removing & re-granting these rules bork the cluster? i assume no, but it's probably prudent to check at some point
#>
    [cmdletbinding()]Param(
        [string]
        $user = "$(whoami)",
        [Parameter()]
        # TODO: https://vexx32.github.io/2018/11/29/Dynamic-ValidateSet/
        [ValidateSet('Default','Remote1')]
        [string]
        $Position = 'Default'
    )

    $PopRegion = $StoredAWSRegion
    $PushRegion = $btd_VPC.$Position.Region

    Write-Verbose "Changing DefaultAWSRegion from '$PopRegion' to '$PushRegion'"
    Set-DefaultAWSRegion $PushRegion

    $sg_id = (Get-Content "./conf/actual/SecurityGroup.$Position.json" | ConvertFrom-Json).GroupId
    $sg = Get-EC2SecurityGroup -Filter @{Name='group-id';Value=$sg_id} 
    $my_ip = (Invoke-WebRequest -Uri "http://ifconfig.me/ip" -TimeoutSec 10).Content 

    if($my_ip){
        Write-Verbose "IP Address parsed as '$my_ip'. Proceeding to update security group ingress rules for '$($sg.GroupId)' for admin '$user'"

        $permSet = $sg.IpPermission | Where-Object {($_.IpV4Ranges.Description -like "*$user*") -and ($_.IpRanges -notcontains "$my_ip/32")}

        Write-Verbose "Count of permissions to be modified: '$($permSet.Count)'"

        foreach($perm in $permSet){
            # TODO: do not copy the entire object or strip typing
            #   see ./.local/vexx32-Reset-CrdbAdminIngress.txt for suggestion details
            New-Variable -Name newPerm -Value ($perm | ConvertTo-Json -Depth 10 | ConvertFrom-Json) -Force

            $oldCidr = ($perm.IpV4Ranges | Where-Object {$_.Description -like "*$user*"}).CidrIp

            $newPerm.IpRanges = ($newPerm.IpRanges -ne $oldCidr) + "$my_ip/32"
            $newPerm.IpRange = ($newPerm.IpRange -ne $oldCidr) + "$my_ip/32"
            $newPerm.Ipv4Ranges | Where-Object {$_.CidrIp -eq $oldCidr} | ForEach-Object {$_.CidrIp = "$my_ip/32"}

            Write-Verbose "Revoking CIDR '$oldCidr'"
            Revoke-EC2SecurityGroupIngress -GroupId $sg.GroupId -IpPermission $perm | Out-Null

            try{
                Grant-EC2SecurityGroupIngress -GroupId $sg.GroupId -IpPermission $newPerm
            }catch{
                Write-Warning "Could not grant modified permission, re-applying permission"
                Write-Host "----------- FAILED PERMISSION -----------"
                $newPerm | ConvertTo-Json -Depth 5 | jq
                Write-Host "-----------------------------------------"
                Write-Host "----------- ORIGINAL PERMISSION ---------"
                $perm | ConvertTo-Json -Depth 5 | jq 
                Write-Host "-----------------------------------------"
                Grant-EC2SecurityGroupIngress -GroupId $sg.GroupId -IpPermission $perm
            }
        }

    }else{
        Write-Error "IP address not determined. No changes attempted. Exiting..."
    }

    Get-EC2SecurityGroup -Filter @{Name='group-id';Value=$sg.GroupId} | ConvertTo-Json -Depth 5 | Set-Content "./conf/actual/SecurityGroup.$Position.json" -Force

    Write-Verbose "Changing DefaultAWSRegion from '$PushRegion' to '$PopRegion'"
    Set-DefaultAWSRegion $PopRegion
}
