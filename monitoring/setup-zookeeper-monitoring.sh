#!/usr/bin/env bash

. common.env

IP=$1
DNS=$2
echo "Installing jmx exporter & jolokia agent on $DNS with IP: $IP"

sudo mkdir -p /opt/zookeeper/monitoring

sudo curl -LO https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/${JMX_EXPORTER_VERSION}/jmx_prometheus_javaagent-${JMX_EXPORTER_VERSION}.jar
sudo curl -LO https://repo1.maven.org/maven2/org/jolokia/jolokia-jvm/${JOLOKIA_AGENT_VERSION}/jolokia-jvm-${JOLOKIA_AGENT_VERSION}.jar
sudo curl -LO https://github.com/prometheus/jmx_exporter/blob/main/example_configs/zookeeper.yaml

sudo mv /home/vagrant/jmx_prometheus_javaagent-${JMX_EXPORTER_VERSION}.jar /opt/zookeeper/monitoring/
sudo mv /home/vagrant/zookeeper.yaml /opt/zookeeper/monitoring/config.yaml
sudo mv /home/vagrant/jolokia-jvm-${JOLOKIA_AGENT_VERSION}.jar /opt/zookeeper/monitoring/jolokia-jvm-${JOLOKIA_AGENT_VERSION}.jar

sudo tee -a  /opt/zookeeper/.bashrc <<EOF
export SERVER_JVMFLAGS="-Dzookeeper.jmx.log4j.disable=true -javaagent:/opt/zookeeper/monitoring/jmx_prometheus_javaagent-${JMX_EXPORTER_VERSION}.jar=8081:/opt/zookeeper/monitoring/config.yaml -javaagent:/opt/zookeeper/monitoring/jolokia-jvm-${JOLOKIA_AGENT_VERSION}.jar=host=*"
EOF

sudo tee -a /opt/zookeeper/conf/zoo.cfg <<EOF
metricsProvider.className=org.apache.zookeeper.metrics.prometheus.PrometheusMetricsProvider
metricsProvider.httpPort=7000
EOF

sudo chown -R zookeeper:zookeeper /opt/zookeeper
sudo su - zookeeper -c "source /opt/zookeeper/.bashrc  && /opt/zookeeper/bin/zkServer.sh --config /opt/zookeeper/conf stop"
sudo su - zookeeper -c "source /opt/zookeeper/.bashrc  && /opt/zookeeper/bin/zkServer.sh --config /opt/zookeeper/conf start"


