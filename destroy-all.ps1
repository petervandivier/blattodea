#!/usr/bin/env pwsh

./destroy/peering
./destroy-region Remote1
./destroy-region Default -LocalToo
