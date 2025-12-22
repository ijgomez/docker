FROM tomcat:8.5-jdk8-temurin

RUN rm -rf /usr/local/tomcat/webapps.dist && \
    rm -rf /usr/local/tomcat/webapps/*

EXPOSE 8080
CMD ["catalina.sh", "run"]
