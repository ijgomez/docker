FROM tomcat:8.5-jdk8-temurin

# Reduce size: remove default apps (optional)
RUN rm -rf /usr/local/tomcat/webapps.dist && \
    rm -rf /usr/local/tomcat/webapps/*

# Default webapps (manager/host-manager) can be added back if needed

EXPOSE 8080
CMD ["catalina.sh", "run"]
