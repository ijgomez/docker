FROM tomcat:9.0-jdk8-temurin

# Opcional: limpiar webapps por defecto
RUN rm -rf /usr/local/tomcat/webapps.dist && \
    rm -rf /usr/local/tomcat/webapps/*

EXPOSE 8080
CMD ["catalina.sh", "run"]
