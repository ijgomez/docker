# Derived from official mysql image (our base image)
FROM mysql
# Add a database
ENV MYSQL_DATABASE company

COPY init.sql /docker-entrypoint-initdb.d/