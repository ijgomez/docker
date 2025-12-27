#!/bin/bash

# Script alternativo para generar certificados con CA propia (sin mkcert)
# Genera una CA local y certificados firmados por ella
# Los certificados deben importarse manualmente en el navegador

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CA_DIR="$SCRIPT_DIR/.ca"
DAYS_VALID=365

echo "=== Generador de CA y Certificados para Stack02 ==="
echo ""

# Crear directorio para la CA si no existe
mkdir -p "$CA_DIR"

# Generar CA si no existe
if [ ! -f "$CA_DIR/ca.key" ] || [ ! -f "$CA_DIR/ca.crt" ]; then
    echo "📋 Generando Autoridad Certificadora (CA) local..."
    
    # Generar clave privada de la CA
    openssl genrsa -out "$CA_DIR/ca.key" 4096
    
    # Generar certificado de la CA
    openssl req -x509 -new -nodes -key "$CA_DIR/ca.key" \
        -sha256 -days 3650 -out "$CA_DIR/ca.crt" \
        -subj "/C=ES/ST=Madrid/L=Madrid/O=Stack02 Dev/OU=IT/CN=Stack02 Local CA"
    
    echo "✅ CA generada en $CA_DIR/"
    echo ""
    echo "⚠️  IMPORTANTE: Debes importar la CA en tu navegador:"
    echo "   Archivo: $CA_DIR/ca.crt"
    echo ""
    echo "   Chrome/Edge:"
    echo "     Settings > Privacy and Security > Security > Manage Certificates"
    echo "     > Authorities > Import > Seleccionar ca.crt"
    echo ""
    echo "   Firefox:"
    echo "     Settings > Privacy & Security > Certificates > View Certificates"
    echo "     > Authorities > Import > Seleccionar ca.crt"
    echo ""
    echo "   macOS Keychain:"
    echo "     sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain $CA_DIR/ca.crt"
    echo ""
else
    echo "✅ CA ya existe en $CA_DIR/"
fi

echo ""
read -p "Presiona Enter para continuar con la generación de certificados..."
echo ""

# Configuración para los certificados
cat > "$CA_DIR/cert.conf" <<EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = v3_req

[dn]
C=ES
ST=Madrid
L=Madrid
O=Stack02
OU=IT
CN=localhost

[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = localhost
DNS.2 = *.localhost
IP.1 = 127.0.0.1
IP.2 = ::1
EOF

# Generar certificados para Apache
echo "🔐 Generando certificados para Apache..."
cd "$SCRIPT_DIR/apache/certs"

# Generar clave privada
openssl genrsa -out server.key 2048

# Generar CSR (Certificate Signing Request)
openssl req -new -key server.key -out server.csr -config "$CA_DIR/cert.conf"

# Firmar el certificado con la CA
openssl x509 -req -in server.csr -CA "$CA_DIR/ca.crt" -CAkey "$CA_DIR/ca.key" \
    -CAcreateserial -out server.crt -days $DAYS_VALID -sha256 \
    -extensions v3_req -extfile "$CA_DIR/cert.conf"

# Limpiar CSR
rm server.csr

echo "✅ Certificados de Apache generados"
cd "$SCRIPT_DIR"
echo ""

# Generar certificados para Wildfly
echo "🔐 Generando keystore para Wildfly..."
cd "$SCRIPT_DIR/wildfly/certs"

# Generar clave privada
openssl genrsa -out wildfly.key 2048

# Generar CSR
openssl req -new -key wildfly.key -out wildfly.csr -config "$CA_DIR/cert.conf"

# Firmar el certificado con la CA
openssl x509 -req -in wildfly.csr -CA "$CA_DIR/ca.crt" -CAkey "$CA_DIR/ca.key" \
    -CAcreateserial -out wildfly.crt -days $DAYS_VALID -sha256 \
    -extensions v3_req -extfile "$CA_DIR/cert.conf"

# Convertir a PKCS12
openssl pkcs12 -export -in wildfly.crt -inkey wildfly.key \
    -out wildfly.p12 -name wildfly -passout pass:password \
    -CAfile "$CA_DIR/ca.crt" -caname root

# Convertir PKCS12 a JKS
keytool -importkeystore \
    -srckeystore wildfly.p12 -srcstoretype PKCS12 -srcstorepass password \
    -destkeystore wildfly.keystore -deststoretype JKS -deststorepass password \
    -noprompt

# Limpiar archivos temporales
rm wildfly.p12 wildfly.key wildfly.crt wildfly.csr

echo "✅ Keystore de Wildfly generado"
cd "$SCRIPT_DIR"
echo ""

echo "=========================================="
echo "✅ Certificados generados exitosamente"
echo ""
echo "⚠️  IMPORTANTE: Debes importar la CA en tu navegador:"
echo "   Archivo: $CA_DIR/ca.crt"
echo ""
echo "Para aplicar los cambios:"
echo "  docker compose restart apache wildfly"
echo ""
echo "Accesos HTTPS:"
echo "  - Apache:  https://localhost"
echo "  - Wildfly: https://localhost:8443"
echo "=========================================="
