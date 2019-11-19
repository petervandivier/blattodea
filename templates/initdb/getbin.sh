#!/usr/bin/env bash

yum install -y wget
wget -qO- https://binaries.cockroachdb.com/cockroach-v19.2.0.linux-amd64.tgz | tar xvz
yes | cp -f cockroach-v19.2.0.linux-amd64/cockroach /usr/local/bin
