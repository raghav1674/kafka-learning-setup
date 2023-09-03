#!/usr/bin/env bash

. common.env

if [ "$GEN_CA" == 1 ]
    then 
        echo "generating ca-cert"
        ./ssl-setup/scripts/create-ca.sh
    else
        echo "skip generating ca-cert"
fi

for i in `seq 1 ${NUM_BROKERS}`; 
    do 
        echo "Broker-$i Node: ${BROKER_NETWORK}$i:9092" ; 
        IP=${BROKER_NETWORK}$i
        DNS=broker$i
        echo "Generating keystore and truststore for broker$i with IP SAN as ${BROKER_NETWORK}$i"
        ./ssl-setup/scripts/create-cert-broker.sh $IP $DNS
        BROKER_ID=$i vagrant upload ssl/$DNS/ /home/vagrant/$DNS $DNS
        BROKER_ID=$i vagrant ssh $DNS -c "sudo mkdir -p /opt/kafka/ssl"
        BROKER_ID=$i vagrant ssh $DNS -c "sudo cp -rf /home/vagrant/$DNS/kafka.server.*  /opt/kafka/ssl"
        BROKER_ID=$i vagrant ssh $DNS -c "sudo sed -i 's/^listeners/#listeners/g' /opt/kafka/config/server.properties"
        BROKER_ID=$i vagrant ssh $DNS -c "sudo cat /opt/kafka/config/server.properties /home/vagrant/$DNS/*.properties > /home/vagrant/server.properties"
        BROKER_ID=$i vagrant ssh $DNS -c "sudo cp  /home/vagrant/server.properties /opt/kafka/config/server.properties"
        BROKER_ID=$i vagrant ssh $DNS -c "sudo chown -R kafka:kafka /opt/kafka"
        BROKER_ID=$i vagrant ssh $DNS -c "sudo su - kafka -c \"/opt/kafka/bin/kafka-server-stop.sh  -daemon /opt/kafka/config/server.properties\""
        BROKER_ID=$i vagrant ssh $DNS -c "sudo su - kafka -c \"/opt/kafka/bin/kafka-server-start.sh  -daemon /opt/kafka/config/server.properties\""
done;

echo "generating client-cert"
./ssl-setup/scripts/create-cert-client.sh