#!/usr/bin/env bash

IP=$1
DNS=$2

rm -rf ssl/$DNS
mkdir -p ssl/$DNS 
pushd ssl/$DNS
export SRVPASS=serversecret
## create a server certificate
keytool -genkey -keystore kafka.server.keystore.jks -validity 365 -storepass $SRVPASS -keypass $SRVPASS  -dname "CN=$DNS" -ext SAN=IP:$IP,DNS:$DNS  -storetype pkcs12
keytool -keystore kafka.server.keystore.jks -certreq -file cert-file -storepass $SRVPASS -keypass $SRVPASS  -dname "CN=$DNS" -ext SAN=IP:$IP,DNS:$DNS

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
keytool -keystore kafka.server.truststore.jks -alias CARoot -import -file ../ca/ca-cert -storepass $SRVPASS -keypass $SRVPASS -noprompt
# Import CA and the signed server certificate into the keystore
keytool -keystore kafka.server.keystore.jks -alias CARoot -import -file ../ca/ca-cert -storepass $SRVPASS -keypass $SRVPASS -noprompt
keytool -keystore kafka.server.keystore.jks -import -file cert-signed -storepass $SRVPASS -keypass $SRVPASS -noprompt

# keytool -list -v -keystore kafka.server.keystore.jks

tee $IP.server.ssl.properties <<EOF
listeners=PLAINTEXT://$IP:9092,SSL://$IP:9093
advertised.listeners=PLAINTEXT://$IP:9092,SSL://$IP:9093
ssl.keystore.location=/opt/kafka/ssl/kafka.server.keystore.jks
ssl.keystore.password=$SRVPASS
ssl.key.password=$SRVPASS
ssl.truststore.location=/opt/kafka/ssl/kafka.server.truststore.jks
ssl.truststore.password=$SRVPASS
# to enable the mutual auth using ssl
# ssl.client.auth=required
EOF

popd