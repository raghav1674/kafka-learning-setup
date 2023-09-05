#!/usr/bin/env bash

sudo tee -a  /etc/yum.conf <<EOF
ip_resolve=4
EOF


curl -LO https://rpm.grafana.com/gpg.key 
sudo rpm --import gpg.key


sudo tee /etc/yum.repos.d/grafana.repo <<EOF
[grafana]
name=grafana
baseurl=https://rpm.grafana.com
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
exclude=*beta*
EOF

sudo yum install grafana -y

sudo systemctl enable grafana-server
sudo systemctl start grafana-server