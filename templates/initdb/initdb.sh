#!/usr/bin/env bash

rm -rf /var/lib/cockroach/certs 
mkdir /var/lib/cockroach
useradd cockroach
mv -f certs /var/lib/cockroach/
chown -R cockroach.cockroach /var/lib/cockroach
mv -f securecockroachdb.service /etc/systemd/system/securecockroachdb.service

systemctl daemon-reload
systemctl start securecockroachdb
