#!/usr/bin/env pwsh
#Requires -Module blattodea

. make/vpc
. make/subnet
. make/securitygroup
. make/keypair
. make/cluster
. make/jumpbox
. make/loadbalancer
. make/certs
. make/initdb
. make/postdeploy
