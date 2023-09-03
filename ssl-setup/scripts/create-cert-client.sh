#!/usr/bin/env bash

# Client configuration for using SSL

CN=broker-client 

export CLIPASS=clientpass

rm -rf ssl/$CN
mkdir -p ssl/$CN 

pushd ssl/$CN

export CLIPASS=clientpass

keytool -keystore kafka.client.truststore.jks -alias CARoot -import -file ../ca/ca-cert  -storepass $CLIPASS -keypass $CLIPASS -noprompt

## create client.properties and configure SSL parameters
tee broker.client.properties <<EOF
security.protocol=SSL
ssl.truststore.location=kafka.client.truststore.jks
ssl.truststore.password=clientpass
# if the IP or DNS SAN is not present uncomment the below line to disable the san check
# ssl.endpoint.identification.algorithm=
EOF

## TEST
# kafka-console-producer.sh --broker-list <<your-public-DNS>>:9093 --topic kafka-security-topic --producer.config ~/ssl/client.properties
# kafka-console-consumer.sh --bootstrap-server <<your-public-DNS>>:9093 --topic kafka-security-topic --consumer.config ~/ssl/client.properties