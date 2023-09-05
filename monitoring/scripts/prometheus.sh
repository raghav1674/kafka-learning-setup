#!/usr/bin/env bash

VERSION=2.47.0-rc.0
PROMETHEUS_HOME_DIR=/opt/prometheus

sudo tee -a  /etc/yum.conf <<EOF
ip_resolve=4
EOF

sudo useradd prometheus --comment "Prometheus Service User" --home-dir "${PROMETHEUS_HOME_DIR}"
curl -LO https://github.com/prometheus/prometheus/releases/download/v${VERSION}/prometheus-${VERSION}.linux-amd64.tar.gz
sudo tar -xzvf prometheus-${VERSION}.linux-amd64.tar.gz --strip-components 1 -C ${PROMETHEUS_HOME_DIR}/
sudo mkdir -p ${PROMETHEUS_HOME_DIR}/data

sudo chown -R prometheus:prometheus ${PROMETHEUS_HOME_DIR}

sudo tee /etc/systemd/system/prometheus.service <<EOF 
[Unit]
Description=Prometheus Server
Documentation=https://prometheus.io/docs/introduction/overview/
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Restart=on-failure
ExecStart=${PROMETHEUS_HOME_DIR}/prometheus --config.file=${PROMETHEUS_HOME_DIR}/prometheus.yml --storage.tsdb.path=${PROMETHEUS_HOME_DIR}/data --web.console.templates=${PROMETHEUS_HOME_DIR}/consoles --web.console.libraries=${PROMETHEUS_HOME_DIR}/console_libraries --storage.tsdb.retention.time=30d --web.listen-address=0.0.0.0:9090

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus
