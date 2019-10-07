function Reset-CrdbAdminIngress {
<#
.DESCRIPTION
    one-liner for re-granting access to yourself when you change wifi networks

.TODO
    security-group access is bound to the same [Amazon.EC2.Model.IpPermission] object as personal IP access
    does removing & re-granting these rules bork the cluster? i assume no, but it's probably prudent to check at some point
#>
    [cmdletbinding()]Param(
        [string]$user = "$(whoami)@$(hostname)"
    )

    $sg = Get-EC2SecurityGroup -GroupId (Get-Content ./conf/actual/SecurityGroup.json | ConvertFrom-Json).GroupId
    $my_ip = (Invoke-WebRequest -Uri "http://ifconfig.me/ip" -TimeoutSec 10).Content 

    if($my_ip){
        Write-Verbose "IP Address parsed as '$my_ip'. Proceeding to update security group ingress rules for '$($sg.GroupId)'"

        foreach($perm in ($sg.IpPermission | Where-Object {$_.IpV4Ranges.Description -like "*$user*"})){
            Revoke-EC2SecurityGroupIngress -GroupId $sg.GroupId -IpPermission $perm
            $perm.Ipv4Ranges | ForEach-Object {$_.CidrIp = "$my_ip/32"}
            Grant-EC2SecurityGroupIngress -GroupId $sg.GroupId -IpPermission $perm
        }
    }else{
        Write-Error "IP address could not be retrieved. No changes attempted."
    }

    Get-EC2SecurityGroup -GroupId $sg.GroupId | ConvertTo-Json -Depth 5 | Set-Content ./conf/actual/SecurityGroup.json -Force
}
