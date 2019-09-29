#!/usr/bin/env bash

yum install -y wget
wget -qO- https://binaries.cockroachdb.com/cockroach-v19.1.4.linux-amd64.tgz | tar xvz
cp -i cockroach-v19.1.4.linux-amd64/cockroach /usr/local/bin
mkdir /var/lib/cockroach
useradd cockroach
mv certs /var/lib/cockroach/
chown -R cockroach.cockroach /var/lib/cockroach

# wget -qO- https://raw.githubusercontent.com/cockroachdb/docs/master/_includes/v19.1/prod-deployment/securecockroachdb.service > /etc/systemd/system/securecockroachdb.service

mv securecockroachdb.service /etc/systemd/system/securecockroachdb.service

systemctl start securecockroachdb
