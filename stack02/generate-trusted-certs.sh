#!/bin/bash

# Script para generar certificados confiables usando mkcert
# Uso: ./generate-trusted-certs.sh

set -e

echo "=== Generador de Certificados Confiables para Stack02 ==="
echo ""

# Verificar si mkcert está instalado
if ! command -v mkcert &> /dev/null; then
    echo " mkcert no está instalado"
    echo ""
    echo "Para instalar mkcert:"
    echo "  - macOS:   brew install mkcert"
    echo "  - Linux:   apt install mkcert  o  yay -S mkcert"
    echo "  - Windows: choco install mkcert"
    echo ""
    echo "Más información: https://github.com/FiloSottile/mkcert"
    exit 1
fi

echo " mkcert encontrado"
echo ""

# Instalar la CA local si no existe
echo " Verificando CA local..."
mkcert -install
echo ""

# Generar certificados para Apache
echo " Generando certificados para Apache..."
cd apache/certs
mkcert -key-file server.key -cert-file server.crt localhost 127.0.0.1 ::1
echo " Certificados de Apache generados en apache/certs/"
cd ../..
echo ""

# Generar certificados para Wildfly
echo " Generando keystore para Wildfly..."
cd wildfly/certs

# Primero generar certificados PEM con mkcert
mkcert -key-file wildfly.key -cert-file wildfly.crt localhost 127.0.0.1 ::1

# Convertir a formato PKCS12 y luego a JKS
openssl pkcs12 -export -in wildfly.crt -inkey wildfly.key \
    -out wildfly.p12 -name wildfly \
    -passout pass:password

# Convertir PKCS12 a JKS (compatible con Wildfly)
keytool -importkeystore \
    -srckeystore wildfly.p12 -srcstoretype PKCS12 -srcstorepass password \
    -destkeystore wildfly.keystore -deststoretype JKS -deststorepass password \
    -noprompt

# Limpiar archivos temporales
rm wildfly.p12 wildfly.key wildfly.crt

echo " Keystore de Wildfly generado en wildfly/certs/"
cd ../..
echo ""

echo "=========================================="
echo " Certificados confiables generados exitosamente"
echo ""
echo "Los certificados son válidos para:"
echo "  - localhost"
echo "  - 127.0.0.1"
echo "  - ::1"
echo ""
echo "Para aplicar los cambios:"
echo "  docker compose down"
echo "  docker compose up -d"
echo ""
echo "Accesos HTTPS:"
echo "  - Apache:  https://localhost"
echo "  - Wildfly: https://localhost:8443"
echo "=========================================="
