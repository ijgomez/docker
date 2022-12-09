FROM nginx:alpine

COPY ./config/default_ssl_pass.conf /etc/nginx/conf.d/default.conf

COPY ./config/localhost.crt /etc/ssl/certs/localhost.crt
COPY ./config/localhost.key /etc/ssl/private/localhost.key

EXPOSE 80
EXPOSE 443

