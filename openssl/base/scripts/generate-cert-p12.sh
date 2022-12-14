#!/bin/ash

openssl pkcs12 -export -out certificate.p12 -in certificate.pem -inkey certificate-private-key.pem

echo "Your certificate p12 is generated"
