FROM httpd:alpine

## Basic
#COPY ./config/httpd.conf /usr/local/apache2/conf/httpd.conf

## SSL
COPY ./config/httpd_ssl.conf /usr/local/apache2/conf/httpd.conf

COPY ./config/ssl/localhost.crt /usr/local/apache2/conf/server.crt
COPY ./config/ssl/localhost.key /usr/local/apache2/conf/server.key

RUN sed -i \
        -e 's/^#\(Include .*httpd-ssl.conf\)/\1/' \
        -e 's/^#\(LoadModule .*mod_ssl.so\)/\1/' \
        -e 's/^#\(LoadModule .*mod_socache_shmcb.so\)/\1/' \
        conf/httpd.conf

EXPOSE 80
EXPOSE 443