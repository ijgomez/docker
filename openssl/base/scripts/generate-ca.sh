#!/bin/ash

openssl genpkey -algorithm RSA -des3 -out ca-private-key.pem -pkeyopt rsa_keygen_bits:4096

openssl req -x509 -new -config ca.conf -key ca-private-key.pem -sha256 -days 3650 -out ca-certificate.pem

echo "Your local CA is generated"

openssl x509 -outform der -in ca-certificate.pem -out ca-certificate.der

openssl x509 -outform der -in ca-certificate.pem -out ca-certificate.crt