FROM alpine:latest

ENV USER tomcat
ENV HOME /home/$USER
ENV APP_DIR /apps

ENV TOMCAT_VERSION 10
ENV TOMCAT_VRS 10.1.4

ENV PG_DRIVER_VERSION 42.5.1

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
RUN apk fetch openjdk17
RUN apk add openjdk17

## Download tomcat
RUN wget https://downloads.apache.org/tomcat/tomcat-$TOMCAT_VERSION/v$TOMCAT_VRS/bin/apache-tomcat-$TOMCAT_VRS.tar.gz

## Install tomcat
RUN mkdir $APP_DIR
RUN tar -zxvf /tmp/apache-tomcat-$TOMCAT_VRS.tar.gz -C $APP_DIR
RUN cd $APP_DIR && mv apache-tomcat-$TOMCAT_VRS tomcat

## Driver PostgreSQL
RUN wget https://jdbc.postgresql.org/download/postgresql-$PG_DRIVER_VERSION.jar
RUN mv /tmp/postgresql-$PG_DRIVER_VERSION.jar $APP_DIR/tomcat/lib

## Copy file confg
COPY ./config/server.xml $APP_DIR/tomcat/conf/server.xml
COPY ./config/logging.properties $APP_DIR/tomcat/conf/logging.properties
COPY ./config/tomcat-users.xml $APP_DIR/tomcat/conf/tomcat-users.xml
COPY ./config/context.xml $APP_DIR/tomcat/conf/context.xml

COPY ./config/context-manager.xml $APP_DIR/tomcat/webapps/manager/META-INF/context.xml
COPY ./config/context-manager.xml $APP_DIR/tomcat/webapps/host-manager/META-INF/context.xml

## Generate keystore and truststore 
RUN mkdir $APP_DIR/tomcat/conf/ssl

## RUN /usr/bin/keytool -genkeypair -keystore $APP_DIR/tomcat/conf/ssl/server.keystore -storepass changeit -alias tomcat -dname 'cn=tomcat-base' -keypass changeit -validity 3600 -keyalg RSA

## (https://blogs.oracle.com/blogbypuneeth/post/create-an-internal-certification-authority-ca-using-keytool-and-sign-your-server-certificate)
RUN /usr/bin/keytool -alias root -dname 'cn=RootCA, ou=Root_CertificateAuthority, o=CertificateAuthority, c=IN' -genkeypair -storepass password -keyalg RSA
RUN /usr/bin/keytool -alias intermediate -dname "cn=IntermediateCA, ou=Intermediate_CertificateAuthority, o=CertificateAuthority, c=IN" -genkeypair -storepass password -keyalg RSA
RUN /usr/bin/keytool -alias server -dname "cn=localhost, ou=Java, o=Oracle, c=IN" -genkeypair -storepass password -keyalg RSA -ext san=ip:127.0.0.1,dns:localhost -keystore $APP_DIR/tomcat/conf/ssl/identity.jks


RUN /usr/bin/keytool -alias intermediate -certreq -storepass password -keyalg RSA | keytool -alias root -gencert -ext san=dns:intermediate -storepass password -keyalg RSA | keytool -alias intermediate -importcert -storepass password -keyalg RSA

RUN /usr/bin/keytool -export -alias root -storepass password | keytool -import -alias root -keystore $APP_DIR/tomcat/conf/ssl/identity.jks -storepass password -noprompt -trustcacerts

RUN /usr/bin/keytool -alias server -certreq -storepass password -keyalg RSA -keystore $APP_DIR/tomcat/conf/ssl/identity.jks | keytool -alias intermediate -gencert -storepass password -keyalg RSA | keytool -alias server -importcert -storepass password -keyalg RSA -keystore $APP_DIR/tomcat/conf/ssl/identity.jks -noprompt -trustcacerts 

RUN /usr/bin/keytool -export -alias intermediate -storepass password | keytool -import -alias intermediate -keystore $APP_DIR/tomcat/conf/ssl/trust.jks -storepass password -trustcacerts -noprompt
RUN /usr/bin/keytool -export -alias root -storepass password | keytool -import -alias root -keystore $APP_DIR/tomcat/conf/ssl/trust.jks -storepass password -trustcacerts -noprompt

## Environment Settings
ENV CATALINA_OPTS="-Xms1G -Xmx1G -Duser.timezone=UTC -Duser.language=en -Duser.region=EN -Dfile.encoding=UTF-8 -Djavax.net.debug=all"

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
