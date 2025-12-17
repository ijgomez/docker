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
stop-embedded-server" && \
rm -rf ${JBOSS_HOME}/standalone/configuration/standalone_xml_history

RUN chmod +x ${JBOSS_HOME}/bin/*.sh

EXPOSE 8080 9990

CMD ["/apps/stack02/wildfly/bin/standalone.sh", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]