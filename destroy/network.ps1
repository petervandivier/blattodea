#!/usr/bin/env pwsh

$vpc =  Get-Content ./conf/actual/VPC.json           | ConvertFrom-Json
$sn  =  Get-Content ./conf/actual/Subnets.json       | ConvertFrom-Json
$igw =  Get-Content ./conf/actual/IGW.json           | ConvertFrom-Json
$sg  =  Get-Content ./conf/actual/SecurityGroup.json | ConvertFrom-Json

$getEni = [scriptblock]{Get-EC2NetworkInterface -Filter @{Name='vpc-id';Value=$vpc.VpcId}}

if(& $getEni){
    while(0 -lt (& $getEni).Count){
        Write-Host "Awaiting termination of all Network Interfaces. $((& $getEni).Count) remain. Sleeping 5..." -ForegroundColor Yellow
        Start-Sleep -Seconds 5
    }
}
Write-Host "$(Get-Date) : all Network Interfaces destroyed" -ForegroundColor Blue

Dismount-EC2InternetGateway -VpcId $igw.Attachments.VpcId -InternetGatewayId $igw.InternetGatewayId

Remove-EC2InternetGateway -InternetGatewayId $igw.InternetGatewayId -Confirm:$false

Remove-EC2SecurityGroup -GroupId $sg.GroupId -Confirm:$false

do{
    $sn.SubnetId | Remove-EC2Subnet -Confirm:$false -ErrorAction SilentlyContinue 
    Write-Host "Could not remove all subnets at this time. Sleeping 5 before retry..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
}while(0 -ne ($sn.SubnetId | Get-EC2Subnet -ErrorAction SilentlyContinue).Count)

Remove-EC2Vpc -VpcId $vpc.VpcId -Confirm:$false
