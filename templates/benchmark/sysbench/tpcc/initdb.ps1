#!/usr/bin/env pwsh

# TODO: debug executing this local to the service

$certsDir = (Resolve-Path "$($btd_Defaults.CertsDirectory)/certs")
$hostAddr = (Get-Content ./conf/actual/Cluster.json | ConvertFrom-Json).Instances[0].PublicIpAddress

cockroach sql --certs-dir=$certsDir --host=$hostAddr --execute="CREATE USER sbtest WITH PASSWORD 'password';"
cockroach sql --certs-dir=$certsDir --host=$hostAddr --execute="CREATE DATABASE sbtest;"
cockroach sql --certs-dir=$certsDir --host=$hostAddr --execute="GRANT ALL ON DATABASE sbtest TO sbtest;"


