#!/usr/bin/env bash

BOOTSTRAP_SERVERS=$1
CLUSTER_SUFFIX=$2
CONNECTOR_IP=$3

. /tmp/files/common.env

sudo echo 'ip_resolve=4' | tee -a  /etc/yum.conf
sudo useradd kafka-connect -d /opt/kafka-connect
sudo mkdir -p  /opt/kafka-connect/{jre,connectors}
sudo tar -xzvf /tmp/files/$JDK_DOWNLOAD_FILE_NAME --strip-components 1 -C /opt/kafka-connect/jre
sudo echo 'export JAVA_HOME=/opt/kafka-connect/jre' >> /opt/kafka-connect/.bashrc
sudo echo 'export PATH=$PATH:$JAVA_HOME/bin' >> /opt/kafka-connect/.bashrc
sudo chown -R kafka-connect:kafka-connect  /opt/kafka-connect
sudo tar -xzvf /tmp/files/$KAFKA_DOWNLOAD_FILE_NAME --strip-components 1 -C /opt/kafka-connect
sudo tee /opt/kafka-connect/config/connect-distributed.properties <<EOF

bootstrap.servers=$BOOTSTRAP_SERVERS
group.id=connect-cluster-${CLUSTER_SUFFIX}

key.converter=org.apache.kafka.connect.json.JsonConverter
value.converter=org.apache.kafka.connect.json.JsonConverter

key.converter.schemas.enable=true
value.converter.schemas.enable=true

internal.key.converter=org.apache.kafka.connect.json.JsonConverter
internal.value.converter=org.apache.kafka.connect.json.JsonConverter
internal.key.converter.schemas.enable=false
internal.value.converter.schemas.enable=false


# this config for dirtributed
offset.storage.topic=connect-offsets-${CLUSTER_SUFFIX}
offset.storage.replication.factor=1

config.storage.topic=connect-configs-${CLUSTER_SUFFIX}
config.storage.replication.factor=1

status.storage.topic=connect-status-${CLUSTER_SUFFIX}
status.storage.replication.factor=1

# this config is only for standalone workers
# offset.storage.file.filename=standalone.offsets

rest.advertised.host.name=${CONNECTOR_IP}
listeners=HTTP://:8084

plugin.path=/opt/kafka-connect/libs,/opt/kafka-connect/connectors,
EOF


sudo chown -R kafka-connect:kafka-connect  /opt/kafka-connect
sudo su - kafka-connect -c "/opt/kafka-connect/bin/connect-distributed.sh -daemon /opt/kafka-connect/config/connect-distributed.properties"