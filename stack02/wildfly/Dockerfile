FROM eclipse-temurin:11-jdk

ENV WILDFLY_VERSION=11.0.0.Final
ENV JBOSS_HOME=/opt/wildfly

RUN apt-get update && apt-get install -y curl unzip && \
  curl -L https://download.jboss.org/wildfly/${WILDFLY_VERSION}/wildfly-${WILDFLY_VERSION}.zip -o /tmp/wildfly.zip && \
  unzip /tmp/wildfly.zip -d /opt && \
  mv /opt/wildfly-${WILDFLY_VERSION} ${JBOSS_HOME} && \
  rm -f /tmp/wildfly.zip && apt-get remove -y unzip && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*

EXPOSE 8080 9990

CMD ["/opt/wildfly/bin/standalone.sh", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]
