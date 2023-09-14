#!/usr/bin/env bash

KSQLDB_IP=$1
BOOTSTRAP_SERVERS=$2

KSQLDB_HOME_DIR=/opt/ksqldb
CONFLUENT_MAJOR_VERSION=7.5
CONFLUENT_MINOR_VERSION=0

sudo tee -a  /etc/yum.conf <<EOF
ip_resolve=4
timeout=60
EOF

# Disable swap
sudo sysctl -w vm.swappiness=1
sudo sysctl -p
sudo swapoff -a
sudo sed -i 's/\/swapfile/#\/swapfile/' /etc/fstab
sudo mount -a

sudo yum install java-1.8.0-openjdk-devel -y
yum install epel-release -y
yum install jq -y

sudo useradd ksqldb --home-dir ${KSQLDB_HOME_DIR} --comment 'Ksqldb Service User'

sudo mkdir -p ${KSQLDB_HOME_DIR}/tmp

sudo curl -O https://packages.confluent.io/archive/${CONFLUENT_MAJOR_VERSION}/confluent-${CONFLUENT_MAJOR_VERSION}.${CONFLUENT_MINOR_VERSION}.tar.gz
sudo tar -xzvf confluent-${CONFLUENT_MAJOR_VERSION}.${CONFLUENT_MINOR_VERSION}.tar.gz --strip-components 1 -C ${KSQLDB_HOME_DIR}/


sudo tee ${KSQLDB_HOME_DIR}/etc/ksqldb/ksql-production-server.properties <<EOF
#------ Endpoint config -------
listeners=http://0.0.0.0:8088
advertised.listener=http://${KSQLDB_IP}:8088

#------ Logging config -------
ksql.logging.processing.topic.auto.create=true
ksql.logging.processing.stream.auto.create=true
#ksql.logging.processing.rows.include=true

#------ External service config -------
bootstrap.servers=${BOOTSTRAP_SERVERS}
compression.type=snappy
#ksql.schema.registry.url=?

#------ Following configs improve performance and reliability of KSQL for critical/production setups. -------
ksql.streams.producer.delivery.timeout.ms=2147483647
ksql.streams.producer.max.block.ms=9223372036854775807

ksql.internal.topic.replicas=1
ksql.internal.topic.min.insync.replicas=1

ksql.streams.replication.factor=1
ksql.streams.producer.acks=all
ksql.streams.topic.min.insync.replicas=1

ksql.streams.state.dir=${KSQLDB_HOME_DIR}/tmp

ksql.streams.num.standby.replicas=1
EOF


sudo chown -R ksqldb:ksqldb  ${KSQLDB_HOME_DIR}/

sudo tee -a ${KSQLDB_HOME_DIR}/.bashrc <<EOF
export PATH=\$PATH:${KSQLDB_HOME_DIR}/bin
export LOG_DIR=${KSQLDB_HOME_DIR}/logs
export JMX_PORT=1099
EOF

sudo tee /etc/systemd/system/ksqldb.service <<EOF 
[Unit]
Description=ksqldb Server
After=network-online.target

[Service]
User=ksqldb
Group=ksqldb
Restart=on-failure
ExecStart=${KSQLDB_HOME_DIR}/bin/ksql-server-start ${KSQLDB_HOME_DIR}/etc/ksqldb/ksql-production-server.properties
ExecStop=${KSQLDB_HOME_DIR}/bin/ksql-server-stop ${KSQLDB_HOME_DIR}/etc/ksqldb/ksql-production-server.properties

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable ksqldb
sudo systemctl start ksqldb

status=""
while [ "$status" != "RUNNING" ];
    do 
        status=$(curl -s localhost:8088/info | jq '.KsqlServerInfo.serverStatus' | tr -d '"')
        echo "Current status is $status"
        sleep 10
done