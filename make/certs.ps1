#!/usr/bin/env pwsh
#Requires -Module blattodea

$sshKey = Resolve-Path -Path "conf/secret/$($btd_Defaults.KeyPair.Name).pem"
$elb = Get-Content -Path ./conf/actual/LoadBalancer.json | ConvertFrom-Json
$ec2 = Get-Content -Path ./conf/actual/Cluster.json      | ConvertFrom-Json
# TODO: 👇 debug this
$elbPublicIpAddress = $null # nslookup $elb.DNSName | grep Server | awk '{print $2}'

$getEc2 = [scriptblock]{Get-EC2Instance -InstanceId $ec2.Instances.InstanceId}

$certDir = $btd_Defaults.CertsDirectory

if(-not (Test-Path $certDir)){
    New-Item -Path $certDir  -ItemType Directory | Out-Null
}
$certDir = Resolve-Path $certDir 

#region pushLocCerts
Push-Location -Path $certDir

New-Item -Path certs             -ItemType Directory -ErrorAction SilentlyContinue
New-Item -Path my-safe-directory -ItemType Directory -ErrorAction SilentlyContinue

Get-ChildItem -Path certs, my-safe-directory | Remove-Item

cockroach cert create-ca --certs-dir=certs --ca-key=my-safe-directory/ca.key

$cluster = (& $getEc2)

$createCertCmdTemplate = @"
cockroach cert create-node {0} {1} {2} {3} localhost 127.0.0.1 {4} {5} {6} --certs-dir=certs --ca-key=my-safe-directory/ca.key
"@

foreach($node in $cluster.Instances){
    $PublicIpAddress = $node.PublicIpAddress 

    $createCertCmd = $createCertCmdTemplate -f @(
        $node.PrivateIpAddress # 0 
        $node.PublicIpAddress  # 1 
        $node.PrivateDnsName   # 2 
        $PublicIpAddress       # 3 
        $elbPublicIpAddress    # 4 
        $elb.DNSName           # 5 
        $null                  # 6 
    )
    Invoke-Expression -Command $createCertCmd 

    dsh -i $sshKey centos@$PublicIpAddress 'mkdir certs'
    dcp -i $sshKey -r certs/ centos@$PublicIpAddress`:~/

    Get-ChildItem -Path certs/node* | Remove-Item
}

cockroach cert create-client root --certs-dir=certs --ca-key=my-safe-directory/ca.key

Pop-Location
#endregion pushLocCerts
