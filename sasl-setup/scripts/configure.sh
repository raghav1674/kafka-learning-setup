#!/usr/bin/env bash

KERBEROS_IP=$1

REALM="KAFKA.SECURE"
ADMINPW="this-is-unsecure"

sudo tee -a  /etc/yum.conf <<EOF
ip_resolve=4
EOF

sudo yum install krb5-server  -y

sudo tee /var/kerberos/krb5kdc/kdc.conf <<EOF
[kdcdefaults]
  kdc_ports = 88
  kdc_tcp_ports = 88
  default_realm=$REALM
[realms]
  $REALM = {
    acl_file = /var/kerberos/krb5kdc/kadm5.acl
    dict_file = /usr/share/dict/words
    admin_keytab = /var/kerberos/krb5kdc/kadm5.keytab
    supported_enctypes = aes256-cts:normal aes128-cts:normal des3-hmac-sha1:normal arcfour-hmac:normal camellia256-cts:normal camellia128-cts:normal des-hmac-sha1:normal des-cbc-md5:normal des-cbc-crc:normal
  }
EOF

sudo tee /var/kerberos/krb5kdc/kadm5.acl <<EOF
*/admin@$REALM *
EOF

sudo tee /etc/krb5.conf <<EOF
[logging]
  default = FILE:/var/log/krb5libs.log
  kdc = FILE:/var/log/krb5kdc.log
  admin_server = FILE:/var/log/kadmind.log

[libdefaults]
    default_realm = $REALM
    kdc_timesync = 1
    ticket_lifetime = 24h

[realms]
    $REALM = {
      admin_server = $KERBEROS_IP
      kdc  = $KERBEROS_IP
      }
EOF



sudo /usr/sbin/kdb5_util create -s -r $REALM -P $ADMINPW
sudo kadmin.local -q "add_principal -pw $ADMINPW admin/admin"

sudo systemctl restart krb5kdc
sudo systemctl restart kadmin

sudo systemctl status krb5kdc
sudo systemctl status kadmin

## create principals
sudo kadmin.local -q "add_principal -randkey reader@KAFKA.SECURE"
sudo kadmin.local -q "add_principal -randkey writer@KAFKA.SECURE"
sudo kadmin.local -q "add_principal -randkey admin@KAFKA.SECURE"

sudo kadmin.local -q "add_principal -randkey kafka/192.168.56.131@KAFKA.SECURE"
sudo kadmin.local -q "add_principal -randkey kafka/broker1@KAFKA.SECURE"

## create keytabs
sudo kadmin.local -q "xst -kt /tmp/reader.user.keytab reader@KAFKA.SECURE"
sudo kadmin.local -q "xst -kt /tmp/writer.user.keytab writer@KAFKA.SECURE"
sudo kadmin.local -q "xst -kt /tmp/admin.user.keytab admin@KAFKA.SECURE"
sudo kadmin.local -q "xst -kt /tmp/kafka.service.keytab kafka/192.168.56.131@KAFKA.SECURE"
sudo kadmin.local -q "xst -kt /tmp/kafka.service.keytab kafka/broker1@KAFKA.SECURE"

sudo chmod a+r /tmp/*.keytab