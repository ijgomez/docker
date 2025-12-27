FROM eclipse-temurin:11-jdk

ENV WILDFLY_VERSION=18.0.1.Final
ENV JBOSS_HOME=/apps/stack02/wildfly

ARG WF_ADMIN_USER=admin
ARG WF_ADMIN_PASSWORD=Admin.1234
ARG WF_SERVER_NAME=default-server

# Instalación básica
RUN mkdir -p /apps/stack02

# Instalación básica de WildFly
RUN apt-get update && apt-get install -y curl unzip && \
    curl -L https://download.jboss.org/wildfly/${WILDFLY_VERSION}/wildfly-${WILDFLY_VERSION}.zip -o /tmp/wildfly.zip && \
    unzip /tmp/wildfly.zip -d /opt && \
    mv /opt/wildfly-${WILDFLY_VERSION} ${JBOSS_HOME} && \
    rm -f /tmp/wildfly.zip && \
    apt-get remove -y unzip && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# Crear usuario administrador
RUN ${JBOSS_HOME}/bin/add-user.sh ${WF_ADMIN_USER} ${WF_ADMIN_PASSWORD} --silent

# --- CONFIGURACIÓN OFFLINE (Sin necesidad de arrancar el servidor) ---
RUN ${JBOSS_HOME}/bin/jboss-cli.sh --commands="\
embed-server --server-config=standalone.xml,\
/:write-attribute(name=name, value=${WF_SERVER_NAME}),\
data-source remove --name=ExampleDS,\
/subsystem=elytron/key-store=httpsKS:add(path=wildfly.keystore, relative-to=jboss.server.config.dir, credential-reference={clear-text=password}, type=JKS),\
/subsystem=elytron/key-manager=httpsKM:add(key-store=httpsKS, credential-reference={clear-text=password}),\
/subsystem=elytron/server-ssl-context=httpsSSC:add(key-manager=httpsKM, protocols=[TLSv1.2]),\
stop-embedded-server" && \
rm -rf ${JBOSS_HOME}/standalone/configuration/standalone_xml_history

# Configurar HTTPS listener en un segundo paso
RUN ${JBOSS_HOME}/bin/jboss-cli.sh --commands="\
embed-server --server-config=standalone.xml,\
if (outcome != success) of /subsystem=undertow/server=default-server/https-listener=https:read-resource,\
/subsystem=undertow/server=default-server/https-listener=https:add(socket-binding=https, ssl-context=httpsSSC, enable-http2=true),\
end-if,\
stop-embedded-server" && \
rm -rf ${JBOSS_HOME}/standalone/configuration/standalone_xml_history

# Crear directorio para certificados
RUN mkdir -p /apps/stack02/certs

# Script para generar keystore si no existe
RUN echo '#!/bin/bash\n\
KEYSTORE_FILE=/apps/stack02/certs/wildfly.keystore\n\
CONFIG_KEYSTORE=${JBOSS_HOME}/standalone/configuration/wildfly.keystore\n\
if [ ! -f "$KEYSTORE_FILE" ]; then\n\
  echo "Generando keystore SSL para WildFly..."\n\
  keytool -genkeypair -alias wildfly -keyalg RSA -keysize 2048 \\\n\
    -validity 365 -keystore "$KEYSTORE_FILE" \\\n\
    -storepass password -keypass password \\\n\
    -dname "CN=localhost, OU=IT, O=Stack02, L=Madrid, ST=Madrid, C=ES"\n\
  echo "Keystore generado en $KEYSTORE_FILE"\n\
else\n\
  echo "Keystore SSL ya existe en $KEYSTORE_FILE"\n\
fi\n\
# Crear enlace simbólico en el directorio de configuración\n\
if [ ! -L "$CONFIG_KEYSTORE" ]; then\n\
  ln -sf "$KEYSTORE_FILE" "$CONFIG_KEYSTORE"\n\
  echo "Enlace simbólico creado: $CONFIG_KEYSTORE -> $KEYSTORE_FILE"\n\
fi\n\
exec ${JBOSS_HOME}/bin/standalone.sh -b 0.0.0.0 -bmanagement 0.0.0.0\n' > /usr/local/bin/wildfly-entrypoint.sh && \
    chmod +x /usr/local/bin/wildfly-entrypoint.sh

RUN chmod +x ${JBOSS_HOME}/bin/*.sh

EXPOSE 8080 8443 9990

CMD ["/usr/local/bin/wildfly-entrypoint.sh"]