
function New-CrdbNode {
<#
.DESCRIPTION
    1. Start a new EC2 instance
    2. Initialize NTP
    3. Rebuild certs for whole cluster with new node
    4. Initialize CockroachDB on new host
    5. Join to the existing cluster

.EXAMPLE
    New-CrdbNode -HostName 'crdb04' -AvailabilityZone 'us-east-2a'

#>
    [cmdletbinding()]Param(
        [string]$HostName,
        [string]$AvailabilityZone # assuming one subnet per AZ i guess
    )

    $subnet = Get-Content ./conf/actual/Subnets.json | ConvertFrom-Json | 
        ForEach-Object { $PSItem } | # `ForEach-Object` is required to unwrap the array for `-eq` eval
        Where-Object {$_.AvailabilityZone -eq $AvailabilityZone}
    $sg_id = (Get-Content ./conf/actual/SecurityGroup.json | ConvertFrom-Json).GroupId
    $kp = Get-Content ./conf/actual/KeyPair.json | ConvertFrom-Json
    $identFile = Resolve-Path "./conf/secret/$($kp.KeyName).pem"
    $ec2 = Get-Content -Path ./conf/actual/Cluster.json | ConvertFrom-Json
    $elb = Get-Content -Path ./conf/actual/LoadBalancer.json | ConvertFrom-Json

    $ami = Invoke-Expression ($btd_Defaults.EC2.Image.Query -join '')
    $ami | ConvertTo-Json -Depth 5 | Set-Content ./conf/actual/AMI.json -Force

    $image_splat = @{
        AssociatePublicIp = $true # TODO: deploy config via user data and rm public IP
        ImageId = $ami.ImageId
        KeyName = $kp.KeyName
        SecurityGroupId = $sg_id
        InstanceType = $btd_Defaults.EC2.InstanceType
        BlockDeviceMapping = @{
            DeviceName="/dev/sda1"
            Ebs = @{
                DeleteOnTermination = $true
            }
        }
        SubnetId = $subnet.SubnetId
        TagSpecification = (ConvertTo-EC2TagSpec -Tags $btd_CommonTags -ResourceType 'instance')
    }

    $n = New-EC2Instance @image_splat
    New-EC2Tag -Resource $n.Instances[0].InstanceId -Tag @([Amazon.EC2.Model.Tag]::new('Name',$HostName))

    $getN = [scriptblock]{Get-EC2Instance @($n.Instances.InstanceId)}
    while((& $getN).Instances.State.Name -ne 'running'){
        Write-Host "Awaiting startup of '$HostName'. Sleeping 10..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
    } 
    Write-Host "$(Get-Date) : node '$HostName' reports running" -ForegroundColor Blue

    foreach($node in (& $getN).Instances) {
        $ip = $node.PublicIpAddress
    
        do {   
            $i++
            Write-Host "Awaiting sshd startup on EC2 instance $HostName. Sleeping 10..." -ForegroundColor Yellow
            Start-Sleep -Seconds 10
        } until ('alive' -eq (dsh -i $identFile -o ConnectTimeout=10 centos@$ip 'echo -n "alive"'))
    
        dsh -i $identFile centos@$ip "sudo hostnamectl set-hostname '$HostName'"
        # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/set-time.html
        dcp -i $identFile ./templates/default/mk-chrony.sh "centos@$ip`:/tmp/"
        dsh -i $identFile centos@$ip 'sudo /tmp/mk-chrony.sh'
    }
    $n = (& $getN)

    $getEc2 = [scriptblock]{Get-EC2Instance (@($n.Instances.InstanceId) + $ec2.Instances.InstanceId)}
    $cluster = (& $getEc2)
    $cluster | ConvertTo-Json -Depth 10 | Set-Content ./conf/actual/Cluster.json -Force

    $allIps = ($cluster.Instances.PrivateIpAddress) -join ','
    $PrivateIpAddress = $n.Instances[0].PrivateIpAddress
    $PublicIpAddress = $n.Instances[0].PublicIpAddress
    
    $tmp = Get-Content ./templates/initdb/securecockroachdb.service.tmp -Raw
    ($tmp -f $PrivateIpAddress, $allIps) | Set-Content ./templates/initdb/securecockroachdb.service -Force
    dcp -i $identFile ./templates/initdb/securecockroachdb.service centos@$PublicIpAddress`:~/
    Remove-Item ./templates/initdb/securecockroachdb.service

    $splat = @{
        Cluster      = $cluster.Instances
        LoadBalancer = $elb
        CertsDir     = Resolve-Path ($btd_Defaults.CertsDirectory)
        OtherNames   = [string]$null
        Clobber      = $true # clobber forces restart
    }
    Build-CrdbCerts @splat   
}

