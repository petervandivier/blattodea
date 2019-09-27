#!/usr/bin/env pwsh

$script:vpc =  Get-Content ./conf/actual/VPC.json           | ConvertFrom-Json
$script:igw =  Get-Content ./conf/actual/IGW.json           | ConvertFrom-Json
$script:ec2 = (Get-Content ./conf/actual/Cluster.json       | ConvertFrom-Json).Instances
$script:sg  =  Get-Content ./conf/actual/SecurityGroup.json | ConvertFrom-Json
$script:sn  =  Get-Content ./conf/actual/Subnets.json       | ConvertFrom-Json

$script:getEc2 = [scriptblock]{Get-EC2Instance $script:ec2.InstanceId}

& $script:getEc2 | Remove-EC2Instance -Confirm:$false 

if(& $script:getEc2){
    while((& $script:getEc2).Instances.State.Name -ne 'terminated'){
        Write-Host "Awaiting termination of all EC2 instances. Sleeping 5..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
    } 
}

Remove-EC2KeyPair -KeyName $btd_Defaults.KeyPair.Name -Confirm:$false 
Remove-Item -Path "./conf/secret/$($script:btd_Defaults.KeyPair.Name).pem"

Dismount-EC2InternetGateway -VpcId $script:igw.Attachments.VpcId -InternetGatewayId $script:igw.InternetGatewayId

Remove-EC2InternetGateway -InternetGatewayId $script:igw.InternetGatewayId -Confirm:$false

Remove-EC2SecurityGroup -GroupId $script:sg.GroupId -Confirm:$false

$script:sn.SubnetId | Remove-EC2Subnet -Confirm:$false

Remove-EC2Vpc -VpcId $script:vpc.VpcId -Confirm:$false

# Remove-Item ./conf/actual/VPC.json
# Remove-Item ./conf/actual/IGW.json
# Remove-Item ./conf/actual/Cluster.json
# Remove-Item ./conf/actual/SecurityGroup.json
# Remove-Item ./conf/actual/Subnets.json
