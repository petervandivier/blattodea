#!/usr/bin/env pwsh
#Requires -Module blattodea

$tpccDir = Resolve-Path ./templates/benchmark/sysbench/tpcc
$identFile = Resolve-Path ./conf/secret/cockroachdb.pem
$hostAddr = (Get-Content ./conf/actual/Cluster.json | ConvertFrom-Json).Instances[0].PublicIpAddress

. $tpccDir/initdb

dcp -i $identFile -r $tpccDir centos@$hostAddr`:~/
dsh -i $identFile centos@$hostAddr 'sudo bash ./tpcc/initpkg.sh'
dsh -i $identFile centos@$hostAddr 'sudo bash ./tpcc/run.sh'

dcp -i $identFile -r centos@$hostAddr`:/tmp/sysbench-out "~/Desktop/$($btd_Defaults.EC2.InstanceType)-crdb"

New-Item -Path "~/Desktop/$($btd_Defaults.EC2.InstanceType)-crdb/$(Get-Date -UFormat '%Y%m%d%H%M%Z')" -Force

