#!/bin/bash
if [ "$#" != 2 ]; then
  if [ "$#" == 1 ]; then
  echo "WARNING: Not using FQDN, if you want to use run: ./cert_generate.sh <ip address> <FQDN>"
    DNSNAME=$1
    IPADDR=$1
    else
    echo "usage ./cert_generate.sh <ip address> <FQDN>"
    exit
  fi
else
  IPADDR=$1
  DNSNAME=$2
fi

IPADD=$1


SERIAL=$(echo $((1 + RANDOM % 10000)))
rm -rf tmp-files/*
rm -rf OUTPUT/*
touch tmp-files/index.txt
touch tmp-files/serial
echo $SERIAL > tmp-files/serial
echo "unique_subject = no" > tmp-files/index.txt.attr




sudo yum install -y crudini


#crudini --set conf-input/openssl.cnf " req_distinguished_name " countryName_default "ES"
#crudini --set conf-input/openssl.cnf " req_distinguished_name " stateOrProvinceName_default "Madrid"
#crudini --set conf-input/openssl.cnf " req_distinguished_name " localityName_default "Madrid"
#crudini --set conf-input/openssl.cnf " req_distinguished_name " organizationalUnitName_default "Red Hat"
if [ "$#" == 2 ]; then
  crudini --set conf-input/openssl.cnf " req_distinguished_name " commonName_default  ${DNSNAME}
else
  crudini --set conf-input/openssl.cnf " req_distinguished_name " commonName_default  ${IPADDR}
fi

crudini --set conf-input/openssl.cnf " alt_names " IP.1 ${IPADDR}
crudini --set conf-input/openssl.cnf " alt_names " DNS.1 ${IPADDR}
if [ "$#" == 2 ]; then
crudini --set conf-input/openssl.cnf " alt_names " DNS.2 ${DNSNAME}
fi


## Generate CA if no cacert included
#openssl genrsa -out OUTPUT/ca.key.pem 4096
#openssl req  -key OUTPUT/ca.key.pem -new -x509 -days 7300 -extensions v3_ca -out OUTPUT/cacert.pem -subj "/C=ES/ST=Spain/L=Madrid/O=Red Hat/emailAddress=larizmen@redhat.com"
cp -p conf-input/cacert.pem OUTPUT/cacert.pem
cp -p conf-input/ca.key.pem OUTPUT/ca.key.pem

# Generate server private key
openssl genrsa -out OUTPUT/server.key.pem 2048


# Grenerate CSR
openssl req -subj "/CN=${DNSNAME}" -config conf-input/openssl.cnf -key OUTPUT/server.key.pem -new -out tmp-files/server.csr.pem


# Generate certificate
sudo openssl ca -config conf-input/openssl.cnf -extensions v3_req -days 3650 -in tmp-files/server.csr.pem -out OUTPUT/server.crt.pem -cert OUTPUT/cacert.pem -keyfile OUTPUT/ca.key.pem


sudo cat OUTPUT/server.crt.pem OUTPUT/server.key.pem > OUTPUT/server.pem
