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


EXPOSE 8080 9990

COPY entrypoint.sh ${JBOSS_HOME}/bin/entrypoint.sh
RUN chmod +x ${JBOSS_HOME}/bin/entrypoint.sh

ENTRYPOINT ["/opt/wildfly/bin/entrypoint.sh"]
CMD ["/opt/wildfly/bin/standalone.sh", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]