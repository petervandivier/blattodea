#!/usr/bin/env pwsh

$igw =  Get-Content ./conf/actual/IGW.json           | ConvertFrom-Json
$ec2 = (Get-Content ./conf/actual/Cluster.json       | ConvertFrom-Json).Instances
$sg  =  Get-Content ./conf/actual/SecurityGroup.json | ConvertFrom-Json

$getEc2 = [scriptblock]{Get-EC2Instance $ec2.InstanceId}

& $getEc2 | Remove-EC2Instance -Confirm:$false 

if(& $getEc2){
    while((& $getEc2).Instances.State.Name -ne 'terminated'){
        Write-Host "Awaiting termination of all EC2 instances. Sleeping 5..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
    } 
}

Remove-EC2KeyPair -KeyName $btd_Defaults.KeyPair.Name -Confirm:$false 
Remove-Item -Path "./conf/secret/$($btd_Defaults.KeyPair.Name).pem"

Dismount-EC2InternetGateway -VpcId $igw.Attachments.VpcId -InternetGatewayId $igw.InternetGatewayId

Remove-EC2InternetGateway -InternetGatewayId $igw.InternetGatewayId -Confirm:$false

Remove-EC2SecurityGroup -GroupId $sg.GroupId -Confirm:$false

# Remove-Item ./conf/actual/IGW.json
# Remove-Item ./conf/actual/Cluster.json
# Remove-Item ./conf/actual/SecurityGroup.json
