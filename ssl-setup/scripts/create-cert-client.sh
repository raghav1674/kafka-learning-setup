#!/usr/bin/env bash

# Client configuration for using SSL
IP=127.0.0.1
DNS=$(hostname)

rm -rf ssl/$DNS
mkdir -p ssl/$DNS 
pushd ssl/$DNS

export SRVPASS=serversecret
export CLIPASS=clientpass
## create a server certificate
keytool -genkey -keystore $IP.client.keystore.jks -validity 365 -storepass $CLIPASS -keypass $CLIPASS  -dname "CN=$DNS" -ext SAN=IP:$IP,DNS:$DNS  -storetype pkcs12
keytool -keystore $IP.client.keystore.jks -certreq -file cert-file -storepass $CLIPASS -keypass $CLIPASS  -dname "CN=$DNS" -ext SAN=IP:$IP,DNS:$DNS

tee $IP-cert.cnf <<EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = req_ext
prompt = no

[req_distinguished_name]
C   = IN
ST  = Kafka
L   = Kafka
O   = Kafka
OU  = Kafka
CN  = $DNS

[req_ext]
subjectAltName = @alt_names

[alt_names]
IP.1 = $IP
DNS.1 = $DNS
EOF

## sign the server certificate => output: file "cert-signed"
openssl x509 -req -CA ../ca/ca-cert -CAkey ../ca/ca-key -in cert-file -out cert-signed -days 365 -CAcreateserial -passin pass:$SRVPASS -extfile $IP-cert.cnf -extensions req_ext
# Trust the CA by creating a truststore and importing the ca-cert
keytool -keystore $IP.client.truststore.jks -alias CARoot -import -file ../ca/ca-cert -storepass $CLIPASS -keypass $CLIPASS -noprompt
# Import CA and the signed server certificate into the keystore
keytool -keystore $IP.client.keystore.jks -alias CARoot -import -file ../ca/ca-cert -storepass $CLIPASS -keypass $CLIPASS -noprompt
keytool -keystore $IP.client.keystore.jks -import -file cert-signed -storepass $CLIPASS -keypass $CLIPASS -noprompt


## create client.properties and configure SSL parameters
tee $IP.client.properties <<EOF
security.protocol=SSL
ssl.truststore.location=$IP.client.truststore.jks
ssl.truststore.password=$CLIPASS
ssl.keystore.location=$IP.client.keystore.jks
ssl.keystore.password=$CLIPASS
ssl.key.password=$CLIPASS
# if the IP or DNS SAN is not present uncomment the below line to disable the san check
# ssl.endpoint.identification.algorithm=
EOF

popd

# Test
# kafka-console-producer  --bootstrap-server <broker-ip>:9093 --topic kafka-security-topic --producer.config 127.0.0.1.client.properties