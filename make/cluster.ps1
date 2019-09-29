#!/usr/bin/env pwsh
#Requires -Module blattodea

#region Header

$kp = New-EC2KeyPair -KeyName $btd_Defaults.KeyPair.Name

$sshKey = Resolve-Path "conf/secret/$($btd_Defaults.KeyPair.Name).pem"

$kp.KeyMaterial | Set-Content $sshKey -Force
chmod 0600 $sshKey

#endregion Header

#region vpcAndSubnet

$vpc = New-EC2Vpc -CidrBlock $btd_VPC.CidrBlock
New-EC2Tag -ResourceId $vpc.VpcId -Tag $btd_Defaults.VPC.Tags
New-EC2Tag -ResourceId $vpc.VpcId -Tag $btd_CommonTags.ToTagArray()
$vpc = Get-EC2Vpc -VpcId $vpc.VpcId # do we need to refresh?

$subnets = @()

foreach($sn in $btd_Subnets){
# New-EC2Subnet doesn't accept tags and i can't think of a sensible way to splat 
    $Subnet = New-EC2Subnet -VpcId $vpc.VpcId -CidrBlock $sn.CidrBlock -AvailabilityZone $sn.AvailabilityZone
    New-EC2Tag -ResourceId $Subnet.SubnetId -Tag $sn.Tags
    New-EC2Tag -ResourceId $Subnet.SubnetId -Tag $btd_CommonTags.ToTagArray()

    $subnets += $Subnet.SubnetId
}

$subnets = Get-EC2Subnet -SubnetId $subnets

$igw = New-EC2InternetGateway
New-EC2Tag -ResourceId $igw.InternetGatewayId -Tag $btd_CommonTags.ToTagArray()
Add-EC2InternetGateway -VpcId $vpc.VpcId -InternetGatewayId $igw.InternetGatewayId
$igw = Get-EC2InternetGateway -InternetGatewayId $igw.InternetGatewayId

#endregion vpcAndSubnet

#region SecurityGroup

$sg_id = New-EC2SecurityGroup -GroupName $btd_SecurityGroup.GroupName -Description $btd_SecurityGroup.Description -VpcId $vpc.VpcId
New-EC2Tag -Resource $sg_id -Tag $btd_SecurityGroup.Tags
New-EC2Tag -Resource $sg_id -Tag $btd_CommonTags.ToTagArray()

# https://docs.aws.amazon.com/sdkfornet/v3/apidocs/index.html?page=EC2/TEC2IpPermission.html&tocid=Amazon_EC2_Model_IpPermission

$btd_IpPermissions.SetSecurityGroup($sg_id)
$btd_IpPermissions.SetMyIp()
Grant-EC2SecurityGroupIngress -GroupId $sg_id -IpPermission $btd_IpPermissions

$rtb = Get-EC2RouteTable -Filter @{Name='vpc-id';Values=$vpc.VpcId}

New-EC2Tag -ResourceId $rtb.RouteTableId -Tag $btd_CommonTags.ToTagArray()
New-EC2Route -RouteTableId $rtb.RouteTableId -GatewayId $igw.InternetGatewayId -DestinationCidrBlock '0.0.0.0/0' | Out-Null 

#endregion SecurityGroup

#region EC2

# most recently available aws marketplace community ami centos image
# https://wiki.centos.org/Cloud/AWS
$centos_image = Get-EC2Image -Filter @{Name='product-code';Values='aw0evgkw8e5c1q413zgy5pjce'} |
    Sort-Object -Property CreationDate -Descending | 
    Select-Object -First 1

$image_splat = @{
    AssociatePublicIp = $true # TODO: deploy config via user data and rm public IP
    ImageId = $centos_image.ImageId
    KeyName = $kp.KeyName
    SecurityGroupId = $sg_id
    InstanceType = $btd_Defaults.EC2.InstanceType
    BlockDeviceMapping = @{
        DeviceName="/dev/sda1"
        Ebs = @{
            DeleteOnTermination = $true
        }
    }
    SubnetId = [string]$null
    TagSpecification = (ConvertTo-EC2TagSpec -Tags $btd_CommonTags -ResourceType 'instance')
}
$cluster = @()

foreach($sn in $subnets){
    $image_splat.SubnetId = $sn.SubnetId
    $n = New-EC2Instance @image_splat
    $cluster += $n
}

$cluster = Get-EC2Instance -InstanceId $cluster.Instances.InstanceId
# TODO: add method to cluster object to self-update SMO-style
# Add-Member -InputObject $cluster -Name Sync -Value {$this = (Get-EC2Instance @($cluster.Instances.InstanceId))}

$cluster.RunningInstance.InstanceId | ForEach-Object {
    $i+=1
    $name = $btd_Defaults.EC2.NamePattern -f $i
    New-EC2Tag -Resource $_ -Tag @([Amazon.EC2.Model.Tag]::new('Name',$name))
}

$cluster = Get-EC2Instance @($cluster.Instances.InstanceId)

# copy instance tags to underlying volumes
foreach($node in ($cluster.Instances)){
    foreach($device in ($node.BlockDeviceMappings.Ebs.VolumeId)){
        $node.Tags | ForEach-Object {
            New-EC2Tag -Resource $device -Tag $_
        }
    }
}

$cluster = Get-EC2Instance @($cluster.Instances.InstanceId)

#endregion EC2

# $cluster = Get-EC2Instance -Filter @{Name='tag:platform';Values='cockroachdb'}

$getEc2 = [scriptblock]{Get-EC2Instance @($cluster.Instances.InstanceId)}

while((& $getEc2).Instances.State.Name -ne 'running'){
    Write-Host "Awaiting startup of all EC2 instances. Sleeping 5..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
} 

Write-Host "$(Get-Date) : all nodes report running" -ForegroundColor Blue

$cluster = (& $getEc2)

Get-EC2SecurityGroup $sg_id | 
            ConvertTo-Json -Depth 5 | Set-Content ./conf/actual/SecurityGroup.json -Force
$vpc      | ConvertTo-Json -Depth 5 | Set-Content ./conf/actual/VPC.json           -Force
$subnets  | ConvertTo-Json -Depth 5 | Set-Content ./conf/actual/Subnets.json       -Force
$igw      | ConvertTo-Json -Depth 5 | Set-Content ./conf/actual/IGW.json           -Force
$cluster  | ConvertTo-Json -Depth 5 | Set-Content ./conf/actual/Cluster.json       -Force

foreach($node in $cluster.Instances) {
    $nodeName = ($node.Tags | Where-Object Key -eq Name).Value
    $ip = $node.PublicIpAddress

    if('alive' -ne (dsh -i $sshKey -o ConnectTimeout=10 centos@$ip 'echo -n "alive"')){
        do {   
            if(0 -eq ($i % 6)){ Write-Host "-- You may press ctrl+c to abort. This is the last step in make/cluster" -ForegroundColor Blue }
            $i++

            Write-Host "Awaiting sshd startup on EC2 instance $nodeName. Sleeping 5..." -ForegroundColor Yellow
            Start-Sleep -Seconds 5
        } until ('alive' -eq (dsh -i $sshKey -o ConnectTimeout=10 centos@$ip 'echo -n "alive"'))
    }

# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/set-time.html
    dcp -i $sshKey ./templates/default/mk-chrony.sh "centos@$ip`:/tmp/"
    dsh -i $sshKey centos@$ip 'sudo /tmp/mk-chrony.sh'
}
