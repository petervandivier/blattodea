#!/usr/bin/env pwsh
#Requires -Module blattodea

$ec2 = Get-Content -Path ./conf/actual/Cluster.json      | ConvertFrom-Json

$certDir = Resolve-Path -Path ($btd_Defaults.CertsDirectory)
$sshKey = Resolve-Path -Path "$jira_ticket.pem" 
$getEc2 = [scriptblock]{Get-EC2Instance -InstanceId $ec2.Instances.InstanceId}
$cluster = (& $getEc2)

$tmp = Get-Content ./templates/initdb/securecockroachdb.service.tmp -Raw
$allIps = ($cluster.Instances.PrivateIpAddress) -join ','

foreach($node in $cluster.Instances){
    $PublicIpAddress = $node.PublicIpAddress 
    $PrivateIpAddress = $node.PrivateIpAddress

    ($tmp -f $PrivateIpAddress, $allIps) | Set-Content ./templates/initdb/securecockroachdb.service -Force

    dcp -i $sshKey ./templates/initdb/initdb.sh centos@$PublicIpAddress`:~/  
    dcp -i $sshKey ./templates/initdb/securecockroachdb.service centos@$PublicIpAddress`:~/  
    dsh -i $sshKey centos@$PublicIpAddress 'chmod +x ./initdb.sh && sudo bash ./initdb.sh'

    Remove-Item ./templates/initdb/securecockroachdb.service
}

cockroach init --certs-dir=$certDir/certs --host=$PublicIpAddress
