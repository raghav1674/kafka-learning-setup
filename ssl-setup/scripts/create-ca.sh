#!/usr/bin/env bash

CN=ca

rm -rf ssl/$CN
mkdir -p ssl/$CN 
pushd ssl/$CN
export SRVPASS=serversecret

tee ca.cnf <<EOF
[ req ]
distinguished_name = req_distinguished_name
policy             = policy_match
x509_extensions     = v3_ca

# For the CA policy
[ policy_match ]
countryName             = optional
stateOrProvinceName     = optional
organizationName        = optional
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req_distinguished_name ]
countryName                     = IN
countryName_default             = IN
countryName_min                 = 2
countryName_max                 = 2
stateOrProvinceName             = kafka 
stateOrProvinceName_default     = kafka
localityName                    = kafka
localityName_default            = kafka 
0.organizationName              = kafka
0.organizationName_default      = kafka 
organizationalUnitName          = kafka
organizationalUnitName_default  = Admin 
commonName                      = Kafka-Security-CA
commonName_max                  = 64
emailAddress                    = kafkalocal@test.com
emailAddress_max                = 64

[ v3_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical,CA:true
nsComment = "OpenSSL Generated Certificate"

EOF
## create a server certificate
openssl req -new -newkey rsa:4096 -days 365 -x509 -config ca.cnf -keyout ca-key -out ca-cert -nodes 
popd