#!/usr/bin/env pwsh
#Requires -Module blattodea

$elb = Get-Content -Path ./conf/actual/LoadBalancer.json | ConvertFrom-Json
$ec2 = Get-Content -Path ./conf/actual/Cluster.json      | ConvertFrom-Json
# allow $jb variable to be null for certs initialization
$jb = Get-Content -Path ./conf/actual/JumpBox.json -ErrorAction SilentlyContinue | ConvertFrom-Json -ErrorAction SilentlyContinue

$elbPublicIpAddress = (dig $elb.DNSName +short) -join ' '

$getEc2 = [scriptblock]{Get-EC2Instance -InstanceId $ec2.Instances.InstanceId}

$certDir = $btd_Defaults.CertsDirectory

if(-not (Test-Path $certDir)){
    New-Item -Path $certDir  -ItemType Directory | Out-Null
}
$certDir = Resolve-Path $certDir 
$keyDir = Resolve-Path "$(Get-Location)/conf/secret"

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
    $sshKey = Resolve-Path -Path  "$keyDir/$($node.KeyName).pem"

    $PublicIpAddress = $node.PublicIpAddress 

    $createCertCmd = $createCertCmdTemplate -f @(
        $node.PrivateIpAddress # 0 
        $node.PublicIpAddress  # 1 
        $node.PrivateDnsName   # 2 
        $PublicIpAddress       # 3 
        $elbPublicIpAddress    # 4 
        $elb.DNSName           # 5 
        $jb.Instances.PrivateIpAddress -join ' ' # 6 
    )
    Invoke-Expression -Command $createCertCmd 

    dsh -i $sshKey -o ConnectTimeout=5 centos@$PublicIpAddress 'mkdir certs'
    dcp -i $sshKey -o ConnectTimeout=5 -r certs/ centos@$PublicIpAddress`:~/

    Get-ChildItem -Path certs/node* | Remove-Item
}

cockroach cert create-client root --certs-dir=certs --ca-key=my-safe-directory/ca.key

Pop-Location
