#!/usr/bin/env pwsh
#Requires -Module blattodea

$ec2 = Get-Content -Path ./conf/actual/Cluster.json      | ConvertFrom-Json

$certDir = Resolve-Path -Path ($btd_Defaults.CertsDirectory)
$keyDir = Resolve-Path "$(Get-Location)/conf/secret"
$getEc2 = [scriptblock]{Get-EC2Instance -InstanceId $ec2.Instances.InstanceId}
$cluster = (& $getEc2)

$tmp = Get-Content ./templates/initdb/securecockroachdb.service.tmp -Raw
$allIps = ($cluster.Instances.PrivateIpAddress) -join ','

foreach($node in $cluster.Instances){
    $PublicIpAddress = $node.PublicIpAddress 
    $PrivateIpAddress = $node.PrivateIpAddress
    
    $identFile = Resolve-Path -Path  "$keyDir/$($node.KeyName).pem"

    ($tmp -f $PrivateIpAddress, $allIps) | Set-Content ./templates/initdb/securecockroachdb.service -Force

    dcp -i $identFile -o ConnectTimeout=5 ./templates/initdb/getbin.sh centos@$PublicIpAddress`:~/  
    dcp -i $identFile -o ConnectTimeout=5 ./templates/initdb/initdb.sh centos@$PublicIpAddress`:~/  
    dcp -i $identFile -o ConnectTimeout=5 ./templates/initdb/securecockroachdb.service centos@$PublicIpAddress`:~/  
    
    dsh -i $identFile -o ConnectTimeout=5 centos@$PublicIpAddress 'chmod +x ./getbin.sh && sudo ./getbin.sh'
    dsh -i $identFile -o ConnectTimeout=5 centos@$PublicIpAddress 'chmod +x ./initdb.sh && sudo ./initdb.sh'
    dsh -i $identFile -o ConnectTimeout=5 centos@$PublicIpAddress 'sudo systemctl start securecockroachdb'

    Remove-Item ./templates/initdb/securecockroachdb.service
}

cockroach init --certs-dir=$certDir/certs --host=$PublicIpAddress
