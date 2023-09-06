#!/usr/bin/env bash

. common.env

IP=$1
DNS=$2
echo "Installing jmx exporter & jolokia agent on $DNS with IP: $IP"
sudo mkdir -p /opt/kafka/monitoring
sudo curl -LO https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/${JMX_EXPORTER_VERSION}/jmx_prometheus_javaagent-${JMX_EXPORTER_VERSION}.jar
sudo curl -LO https://repo1.maven.org/maven2/org/jolokia/jolokia-jvm/${JOLOKIA_AGENT_VERSION}/jolokia-jvm-${JOLOKIA_AGENT_VERSION}.jar
sudo curl -LO https://github.com/prometheus/jmx_exporter/blob/main/example_configs/kafka-2_0_0.yml
sudo mv /home/vagrant/jmx_prometheus_javaagent-${JMX_EXPORTER_VERSION}.jar /opt/kafka/monitoring/
sudo mv /home/vagrant/kafka-2_0_0.yml /opt/kafka/monitoring/config.yaml
sudo mv /home/vagrant/jolokia-jvm-${JOLOKIA_AGENT_VERSION}.jar /opt/kafka/monitoring/jolokia-jvm-${JOLOKIA_AGENT_VERSION}.jar
sudo tee -a  /opt/kafka/.bashrc <<EOF
export KAFKA_OPTS="-javaagent:/opt/kafka/monitoring/jmx_prometheus_javaagent-${JMX_EXPORTER_VERSION}.jar=8080:/opt/kafka/monitoring/config.yaml -javaagent:/opt/kafka/monitoring/jolokia-jvm-${JOLOKIA_AGENT_VERSION}.jar=host=*"
EOF
sudo chown -R kafka:kafka /opt/kafka
sudo su - kafka -c "source /opt/kafka/.bashrc && /opt/kafka/bin/kafka-server-stop.sh  -daemon /opt/kafka/config/server.properties"
sudo su - kafka -c "source /opt/kafka/.bashrc && /opt/kafka/bin/kafka-server-start.sh  -daemon /opt/kafka/config/server.properties"
