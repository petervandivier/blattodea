function Enter-CrdbAdminUi {

    $script:ec2 = Get-Content "./conf/actual/Cluster.json" | ConvertFrom-Json
    $script:IP = $ec2.Instances[0].PublicIPAddress
# $browser = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' "https://$IP`:8080"
# TODO: ¿Start-Process $browser -Async?
    open -a "Firefox" "https://$IP`:8080"
}
