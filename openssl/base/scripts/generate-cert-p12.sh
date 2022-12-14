#!/bin/ash

openssl pkcs12 -export -out certificate.p12 -in certificate.pem -inkey certificate-private-key.pem 
# -passin pass:a123456 -passout pass:a123456

echo "Your certificate p12 is generated"
