#!/usr/bin/env bash

cd /usr/local/share/

curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.rpm.sh | bash

yum -y install sysbench
yum -y install git
git clone https://github.com/Percona-Lab/sysbench-tpcc.git
