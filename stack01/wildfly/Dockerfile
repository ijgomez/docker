FROM eclipse-temurin:11-jdk


ENV WILDFLY_VERSION=11.0.0.Final
ENV JBOSS_HOME=/opt/wildfly


RUN apt-get update && apt-get install -y curl unzip && \
curl -L https://download.jboss.org/wildfly/${WILDFLY_VERSION}/wildfly-${WILDFLY_VERSION}.zip -o wildfly.zip && \
unzip wildfly.zip && \
mv wildfly-${WILDFLY_VERSION} ${JBOSS_HOME} && \
rm wildfly.zip


# PostgreSQL JDBC driver: instalar como módulo de WildFly
RUN mkdir -p ${JBOSS_HOME}/modules/system/layers/base/org/postgresql/main && \
	curl -L https://jdbc.postgresql.org/download/postgresql-42.6.0.jar -o /tmp/postgresql-42.6.0.jar && \
	mv /tmp/postgresql-42.6.0.jar ${JBOSS_HOME}/modules/system/layers/base/org/postgresql/main/postgresql-42.6.0.jar

# Copiar el module descriptor desde el contexto de build
COPY module.xml /opt/wildfly/modules/system/layers/base/org/postgresql/main/module.xml


# Eliminar datasource ExampleDS durante la construcción de la imagen (si existe).
# Usamos el 'jboss-cli' en modo embed-server para modificar la configuración sin
# tener que arrancar el servidor completo.
RUN cat > /tmp/remove-example.cli <<'CLI'
embed-server --server-config=standalone.xml --std-out=echo
/subsystem=datasources/data-source=ExampleDS:remove()
:reload
stop-embedded-server
CLI
RUN /opt/wildfly/bin/jboss-cli.sh --file=/tmp/remove-example.cli || true
RUN rm -f /tmp/remove-example.cli || true


EXPOSE 8080 9990

COPY entrypoint.sh ${JBOSS_HOME}/bin/entrypoint.sh
RUN chmod +x ${JBOSS_HOME}/bin/entrypoint.sh

# Crear usuario no-root 'wildfly' y ajustar permisos para ejecutar WildFly sin root
RUN groupadd -r wildfly && useradd -r -g wildfly -d ${JBOSS_HOME} -s /sbin/nologin wildfly || true
RUN chown -R wildfly:wildfly ${JBOSS_HOME} || true
RUN chmod -R g+rwX ${JBOSS_HOME} || true
RUN chown wildfly:wildfly ${JBOSS_HOME}/bin/entrypoint.sh || true

# NOTA: no cambiamos a USER wildfly aquí para que el entrypoint (ejecutado como root)
# pueda chown los volúmenes montados en tiempo de ejecución y luego ejecutar
# WildFly con el usuario 'wildfly' mediante 'runuser'.

ENTRYPOINT ["/opt/wildfly/bin/entrypoint.sh"]
CMD ["/opt/wildfly/bin/standalone.sh", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]