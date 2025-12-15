FROM eclipse-temurin:11-jdk


ENV WILDFLY_VERSION=11.0.0.Final
ENV JBOSS_HOME=/opt/wildfly


RUN apt-get update && apt-get install -y curl unzip && \
curl -L https://download.jboss.org/wildfly/${WILDFLY_VERSION}/wildfly-${WILDFLY_VERSION}.zip -o wildfly.zip && \
unzip wildfly.zip && \
mv wildfly-${WILDFLY_VERSION} ${JBOSS_HOME} && \
rm wildfly.zip


# PostgreSQL JDBC driver
RUN curl -L https://jdbc.postgresql.org/download/postgresql-42.6.0.jar \
-o ${JBOSS_HOME}/standalone/deployments/postgresql.jar


EXPOSE 8080 9990


CMD ["/opt/wildfly/bin/standalone.sh", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]