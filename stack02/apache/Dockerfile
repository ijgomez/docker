FROM httpd:2.4

# Instalar OpenSSL para generar certificados
RUN apt-get update && \
    apt-get install -y openssl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Crear directorio para certificados
RUN mkdir -p /usr/local/apache2/conf/certs

# Script para generar certificados si no existen
RUN echo '#!/bin/bash\n\
CERT_DIR=/usr/local/apache2/conf/certs\n\
if [ ! -f "$CERT_DIR/server.crt" ] || [ ! -f "$CERT_DIR/server.key" ]; then\n\
  echo "Generando certificados SSL autofirmados..."\n\
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \\\n\
    -keyout "$CERT_DIR/server.key" \\\n\
    -out "$CERT_DIR/server.crt" \\\n\
    -subj "/C=ES/ST=Madrid/L=Madrid/O=Stack02/OU=IT/CN=localhost"\n\
  echo "Certificados generados en $CERT_DIR"\n\
else\n\
  echo "Certificados SSL ya existen, usando los existentes"\n\
fi\n\
exec httpd-foreground\n' > /usr/local/bin/docker-entrypoint.sh && \
    chmod +x /usr/local/bin/docker-entrypoint.sh

CMD ["/usr/local/bin/docker-entrypoint.sh"]
