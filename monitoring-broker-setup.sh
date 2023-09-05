#!/usr/bin/env bash

. common.env

for i in `seq 1 ${NUM_BROKERS}`; 
    do 
        echo "Broker-$i Node: ${BROKER_NETWORK}$i:9092" ; 
        IP=${BROKER_NETWORK}$i
        DNS=broker$i
        echo "Installing jmx exporter on broker$i with IP: ${BROKER_NETWORK}$i"
        BROKER_ID=$i vagrant ssh $DNS -c "sudo mkdir -p /opt/kafka/monitoring"
        BROKER_ID=$i vagrant ssh $DNS -c "sudo curl -LO https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/${JMX_EXPORTER_VERSION}/jmx_prometheus_javaagent-${JMX_EXPORTER_VERSION}.jar"
        BROKER_ID=$i vagrant ssh $DNS -c "sudo curl -LO https://github.com/prometheus/jmx_exporter/blob/main/example_configs/kafka-2_0_0.yml"
        BROKER_ID=$i vagrant ssh $DNS -c "sudo mv /home/vagrant/jmx_prometheus_javaagent-${JMX_EXPORTER_VERSION}.jar /opt/kafka/monitoring/"
        BROKER_ID=$i vagrant ssh $DNS -c "sudo mv /home/vagrant/kafka-2_0_0.yml /opt/kafka/monitoring/config.yaml"
        BROKER_ID=$i vagrant ssh $DNS -c "sudo su - kafka -c \"echo 'export KAFKA_OPTS=-javaagent:/opt/kafka/monitoring/jmx_prometheus_javaagent-${JMX_EXPORTER_VERSION}.jar=8080:/opt/kafka/monitoring/config.yaml $KAFKA_OPTS' | tee -a  /opt/kafka/.bashrc\""
        BROKER_ID=$i vagrant ssh $DNS -c "sudo chown -R kafka:kafka /opt/kafka"
        BROKER_ID=$i vagrant ssh $DNS -c "sudo su - kafka -c \"source /opt/kafka/.bashrc && /opt/kafka/bin/kafka-server-stop.sh  -daemon /opt/kafka/config/server.properties\""
        BROKER_ID=$i vagrant ssh $DNS -c "sudo su - kafka -c \"source /opt/kafka/.bashrc && /opt/kafka/bin/kafka-server-start.sh  -daemon /opt/kafka/config/server.properties\""
done;









