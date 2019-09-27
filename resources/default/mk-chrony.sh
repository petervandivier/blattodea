#!/usr/bin/env bash
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/set-time.html

if [ `whoami` != 'root' ]
then
# https://stackoverflow.com/a/5947802/4709762
    RED='\033[0;31m'
    NC='\033[0m'
    echo -e "${RED}must be executed as root${NC}"
    exit
fi

yum erase 'ntp*'
yum install -y chrony
echo 'server 169.254.169.123 prefer iburst minpoll 4 maxpoll 4' >> /etc/chrony.conf
service chronyd restart
chkconfig chronyd on
chronyc sources -v
chronyc tracking
