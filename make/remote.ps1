#!/usr/bin/env pwsh
#Requires -Module blattodea

./make/vpc Remote1
./make/subnet Remote1
./make/securitygroup Remote1

./make/peering

./make/keypair Remote1
./make/cluster Remote1
./make/loadbalancer Remote1


