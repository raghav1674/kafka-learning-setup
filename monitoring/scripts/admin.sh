#!/usr/bin/env bash

. ../common.env

sudo tee -a  /etc/yum.conf <<EOF
ip_resolve=4
EOF

# Create admin user
sudo useradd kafadmin --home-dir /opt/kafadmin --comment 'Kafka Admin User' --groups wheel
sudo tee /etc/sudoers.d/kafadmin <<EOF
kafadmin ALL=(ALL) NOPASSWD: ALL
EOF

# install docker
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo usermod -G docker kafadmin


sudo su kafadmin <<EOF
# install zoo-navigator
# https://zoonavigator.elkozmon.com/en/latest/docker/configuration.html
docker run \
  -d \
  -p 9001:9001 \
  -e HTTP_PORT=9001 \
  -e CONNECTION_ZK_CONN="${ZOOKEEPER_IP}:2181" \
  --name zoonavigator \
  --restart unless-stopped \
  elkozmon/zoonavigator:latest

# install kafka-manager
# https://github.com/eshepelyuk/cmak-docker/
docker run -d \
     -p 9000:9000  \
     -e ZK_HOSTS="${ZOOKEEPER_IP}:2181" \
     hlebalbau/kafka-manager:stable

# install kafka-monitor
sudo yum install -y git java-1.8.0-openjdk-devel
git clone https://github.com/linkedin/kafka-monitor.git /opt/kafadmin/kafka-monitor
sudo chown -R kafadmin:kafadmin /opt/kafadmin/kafka-monitor
cd /opt/kafadmin/kafka-monitor
./gradlew jar
mkdir -p /opt/kafadmin/kafka-monitor/config/
tee /opt/kafadmin/kafka-monitor/config/xinfra-monitor.properties <<EOF
{
  "single-cluster-monitor": {
    "class.name": "com.linkedin.xinfra.monitor.apps.SingleClusterMonitor",
    "topic": "xinfra-monitor-topic",
    "zookeeper.connect": "${ZOOKEEPER_IP}:2181",
    "bootstrap.servers": "${BROKER_NETWORK}1:9092,${BROKER_NETWORK}2:9092,${BROKER_NETWORK}3:9092",
    "request.timeout.ms": 9000,
    "produce.record.delay.ms": 100,
    "topic-management.topicManagementEnabled": true,
    "topic-management.topicCreationEnabled": true,
    "topic-management.replicationFactor" : 1,
    "topic-management.partitionsToBrokersRatio" : 2.0,
    "topic-management.rebalance.interval.ms" : 600000,
    "topic-management.preferred.leader.election.check.interval.ms" : 300000,
    "topic-management.topicFactory.props": {
    },
    "topic-management.topic.props": {
      "retention.ms": "3600000"
    },
    "produce.producer.props": {
      "client.id": "kmf-client-id"
    },

    "consume.latency.sla.ms": "20000",
    "consume.consumer.props": {
    }
  },

  "offset-commit-service": {
       "class.name": "com.linkedin.xinfra.monitor.services.OffsetCommitService",
        "zookeeper.connect": "${ZOOKEEPER_IP}:2181",
        "bootstrap.servers": "${BROKER_NETWORK}1:9092,${BROKER_NETWORK}2:9092,${BROKER_NETWORK}3:9092",
       "consumer.props": {
           "group.id": "target-consumer-group"
       }
  },
  "jolokia-service": {
    "class.name": "com.linkedin.xinfra.monitor.services.JolokiaService"
  },

  "reporter-service": {
    "class.name": "com.linkedin.xinfra.monitor.services.DefaultMetricsReporterService",
    "report.interval.sec": 1,
    "report.metrics.list": [
        "kmf:type=kafka-monitor:offline-runnable-count",
        "kmf.services:type=produce-service,name=*:produce-availability-avg",
        "kmf.services:type=consume-service,name=*:consume-availability-avg",
        "kmf.services:type=produce-service,name=*:records-produced-total",
        "kmf.services:type=consume-service,name=*:records-consumed-total",
        "kmf.services:type=produce-service,name=*:records-produced-rate",
        "kmf.services:type=produce-service,name=*:produce-error-rate",
        "kmf.services:type=consume-service,name=*:consume-error-rate",
        "kmf.services:type=consume-service,name=*:records-lost-total",
        "kmf.services:type=consume-service,name=*:records-lost-rate",
        "kmf.services:type=consume-service,name=*:records-duplicated-total",
        "kmf.services:type=consume-service,name=*:records-delay-ms-avg",
        "kmf.services:type=commit-availability-service,name=*:offsets-committed-avg",
        "kmf.services:type=commit-availability-service,name=*:offsets-committed-total",
        "kmf.services:type=commit-availability-service,name=*:failed-commit-offsets-avg",
        "kmf.services:type=commit-availability-service,name=*:failed-commit-offsets-total",
        "kmf.services:type=commit-latency-service,name=*:commit-offset-latency-ms-avg",
        "kmf.services:type=commit-latency-service,name=*:commit-offset-latency-ms-max",
        "kmf.services:type=commit-latency-service,name=*:commit-offset-latency-ms-99th",
        "kmf.services:type=commit-latency-service,name=*:commit-offset-latency-ms-999th",
        "kmf.services:type=commit-latency-service,name=*:commit-offset-latency-ms-9999th",
        "kmf.services:type=cluster-topic-manipulation-service,name=*:topic-creation-metadata-propagation-ms-avg",
        "kmf.services:type=cluster-topic-manipulation-service,name=*:topic-creation-metadata-propagation-ms-max",
        "kmf.services:type=cluster-topic-manipulation-service,name=*:topic-deletion-metadata-propagation-ms-avg",
        "kmf.services:type=cluster-topic-manipulation-service,name=*:topic-deletion-metadata-propagation-ms-max",
        "kmf.services:type=offset-commit-service,name=*:offset-commit-availability-avg",
        "kmf.services:type=offset-commit-service,name=*:offset-commit-service-success-rate",
        "kmf.services:type=offset-commit-service,name=*:offset-commit-service-success-total",
        "kmf.services:type=offset-commit-service,name=*:offset-commit-service-failure-rate",
        "kmf.services:type=offset-commit-service,name=*:offset-commit-service-failure-total"
    ]
  },

  "cluster-topic-manipulation-service":{
     "class.name":"com.linkedin.xinfra.monitor.services.ClusterTopicManipulationService",
    "zookeeper.connect": "${ZOOKEEPER_IP}:2181",
    "bootstrap.servers": "${BROKER_NETWORK}1:9092,${BROKER_NETWORK}2:9092,${BROKER_NETWORK}3:9092",
     "topic": "xinfra-monitor-topic"
  },


  "reporter-kafka-service": {
    "class.name": "com.linkedin.xinfra.monitor.services.KafkaMetricsReporterService",
    "report.interval.sec": 3,
    "zookeeper.connect": "${ZOOKEEPER_IP}:2181",
    "bootstrap.servers": "${BROKER_NETWORK}1:9092,${BROKER_NETWORK}2:9092,${BROKER_NETWORK}3:9092",
    "topic": "xinfra-monitor-topic-metrics",
    "report.kafka.topic.replication.factor": 1,
    "report.metrics.list": [
      "kmf.services:type=produce-service,name=*:produce-availability-avg",
      "kmf.services:type=consume-service,name=*:consume-availability-avg",
      "kmf.services:type=produce-service,name=*:records-produced-total",
      "kmf.services:type=consume-service,name=*:records-consumed-total",
      "kmf.services:type=consume-service,name=*:records-lost-total",
      "kmf.services:type=consume-service,name=*:records-duplicated-total",
      "kmf.services:type=consume-service,name=*:records-delay-ms-avg",
      "kmf.services:type=produce-service,name=*:records-produced-rate",
      "kmf.services:type=produce-service,name=*:produce-error-rate",
      "kmf.services:type=consume-service,name=*:consume-error-rate"
    ]
  }
}
EOF

sudo tee /etc/systemd/system/kafka-monitor.service <<EOF
[Unit]
Description=Kafka Monitor
After=network.target

[Service]
User=kafadmin
Group=kafadmin
WorkingDirectory=/opt/kafadmin/kafka-monitor
ExecStart=/opt/kafadmin/kafka-monitor/bin/xinfra-monitor-start.sh /opt/kafadmin/kafka-monitor/config/xinfra-monitor.properties
SuccessExitStatus=143

[Install]
WantedBy=multi-user.target
EOF
EOF

# install yelp/kafka-utils


# install linkedin/kafka-tool