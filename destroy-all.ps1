#!/usr/bin/env pwsh

. destroy/cluster
. destroy/loadbalancer
# TODO: figure out what the subnet deps are and await() shutdown
#   hotlist: ACL, RTB->IGW
. destroy/network
