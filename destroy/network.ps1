#!/usr/bin/env pwsh

[CmdletBinding()]
param (
    [Parameter()]
    # TODO: https://vexx32.github.io/2018/11/29/Dynamic-ValidateSet/
    [ValidateSet('Default','Remote1')]
    [string]
    $Position = 'Default'
)

$PopRegion = $StoredAWSRegion
$PushRegion = $btd_VPC.$Position.Region
Set-DefaultAWSRegion $PushRegion

$vpc =  Get-Content "./conf/actual/VPC.$Position.json"           | ConvertFrom-Json
$sn  =  Get-Content "./conf/actual/Subnets.$Position.json"       | ConvertFrom-Json
$igw =  Get-Content "./conf/actual/IGW.$Position.json"           | ConvertFrom-Json
$sg  =  Get-Content "./conf/actual/SecurityGroup.$Position.json" | ConvertFrom-Json

$getEni = [scriptblock]{Get-EC2NetworkInterface -Filter @{Name='vpc-id';Value=$vpc.VpcId}}
$getSubnet = [scriptblock]{Get-EC2Subnet -Filter @{Name='subnet-id';Value=$sn.SubnetId}}

if(& $getEni){
    while(0 -lt (& $getEni).Count){
        Write-Host "Awaiting termination of all Network Interfaces. $((& $getEni).Count) remain. Sleeping 10..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
    }
}
Write-Host "$(Get-Date) : all Network Interfaces destroyed" -ForegroundColor Blue

Dismount-EC2InternetGateway -VpcId $igw.Attachments.VpcId -InternetGatewayId $igw.InternetGatewayId

Remove-EC2InternetGateway -InternetGatewayId $igw.InternetGatewayId -Confirm:$false

Remove-EC2SecurityGroup -GroupId $sg.GroupId -Confirm:$false

do{
    try {
        (& $getSubnet) | Remove-EC2Subnet -Confirm:$false
    }
    catch {
        Write-Host "Could not remove all subnets at this time. Sleeping 10 before retry..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
    }
}while(0 -lt (& $getSubnet).Count)

Remove-EC2Vpc -VpcId $vpc.VpcId -Confirm:$false

Set-DefaultAWSRegion $PopRegion
