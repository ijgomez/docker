FROM openjdk:8-jdk-alpine

RUN apk -U update && \
    apk add bash curl wget && \
    apk upgrade 

ENV HADOOP_VERSION 2.7.7

RUN curl http://mirrors.ukfast.co.uk/sites/ftp.apache.org/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz | tar xvz && \
    mv hadoop-$HADOOP_VERSION /opt/hadoop && \
    rm -rf /opt/hadoop/share/doc



