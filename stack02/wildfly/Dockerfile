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

# Copiar el keystore al directorio de configuración
COPY ./certs/wildfly.keystore ${JBOSS_HOME}/standalone/configuration/

RUN chmod +x ${JBOSS_HOME}/bin/*.sh

EXPOSE 8080 8443 9990

CMD ["/apps/stack02/wildfly/bin/standalone.sh", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]