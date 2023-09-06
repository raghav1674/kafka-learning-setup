#!/usr/bin/env bash

for i in `seq 2 ${NUM_BROKERS}`; 
    do 
        echo "Broker-$i Node: ${BROKER_NETWORK}$i:9092" ; 
        IP=${BROKER_NETWORK}$i
        DNS=broker$i
        BROKER_ID=$i vagrant upload monitoring/setup-broker-monitoring.sh $DNS
        BROKER_ID=$i vagrant upload common.env $DNS
        BROKER_ID=$i vagrant ssh $DNS -c "sudo chmod +x /home/vagrant/setup-broker-monitoring.sh"
        BROKER_ID=$i vagrant ssh $DNS -c "/home/vagrant/setup-broker-monitoring.sh $IP $DNS"
done;


# echo "Zookeeper Node: ${ZOOKEEPER_IP}:2181" ; 
# IP=${ZOOKEEPER_IP}
# DNS=zk
# vagrant upload monitoring/setup-zookeeper-monitoring.sh $DNS
# vagrant upload common.env $DNS
# vagrant ssh $DNS -c "sudo chmod +x /home/vagrant/setup-zookeeper-monitoring.sh"
# vagrant ssh $DNS -c "/home/vagrant/setup-zookeeper-monitoring.sh $IP $DNS"







