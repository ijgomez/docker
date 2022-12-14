FROM alpine:latest

ENV USER tomcat
ENV HOME /home/$USER
ENV APP_DIR /apps

USER root

## Update Operative System
RUN apk update &&  apk upgrade && apk add sudo

# add new group and user 
RUN adduser -D $USER \
        && echo "$USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER \
        && chmod 0440 /etc/sudoers.d/$USER

## The downloaded files will be placed in /tmp to be deleted at the end.
WORKDIR /tmp

## Install openjdk alpine
RUN apk fetch openjdk12
RUN apk add openjdk12

## Download tomcat 9
RUN wget https://downloads.apache.org/tomcat/tomcat-9/v9.0.70/bin/apache-tomcat-9.0.70.tar.gz

## Install tomcat
RUN mkdir $APP_DIR
RUN tar -zxvf /tmp/apache-tomcat-9.0.70.tar.gz -C $APP_DIR
RUN cd $APP_DIR && mv apache-tomcat-9.0.70 tomcat

## Driver PostgreSQL
RUN wget https://jdbc.postgresql.org/download/postgresql-42.3.3.jar
RUN mv /tmp/postgresql-42.3.3.jar $APP_DIR/tomcat/lib

## Copy file confg
COPY ./config/server.xml $APP_DIR/tomcat/conf/server.xml
COPY ./config/logging.properties $APP_DIR/tomcat/conf/logging.properties
COPY ./config/tomcat-users.xml $APP_DIR/tomcat/conf/tomcat-users.xml
COPY ./config/context.xml $APP_DIR/tomcat/conf/context.xml

COPY ./config/context-manager.xml $APP_DIR/tomcat/webapps/manager/META-INF/context.xml
COPY ./config/context-manager.xml $APP_DIR/tomcat/webapps/host-manager/META-INF/context.xml

## Generate keystore and truststore
RUN mkdir $APP_DIR/tomcat/conf/ssl
RUN /usr/bin/keytool -genkeypair -keystore $APP_DIR/tomcat/conf/ssl/server.keystore -storepass changeit -alias tomcat -dname 'cn=tomcat-base' -keypass changeit -validity 3600 -keyalg RSA

## Environment Settings
ENV CATALINA_OPTS="-Xms1G -Xmx1G -Duser.timezone=UTC -Duser.language=es -Duser.region=ES -Dfile.encoding=UTF-8 -Djavax.net.debug=all"

## Remove examples and docs
RUN rm -rf $APP_DIR/tomcat/webapps/examples
RUN rm -rf $APP_DIR/tomcat/webapps/docs

## Change permissions
RUN chown -R $USER:$USER $APP_DIR/tomcat

## Remove installer downloaded
RUN rm -rf /tmp

USER $USER

WORKDIR $HOME

## Export ports
EXPOSE 8080
EXPOSE 8443

## Volumes
VOLUME $APP_DIR/tomcat/logs

## Start tomcat
CMD sh $APP_DIR/tomcat/bin/catalina.sh start && tail -f $APP_DIR/tomcat/logs/catalina.out
