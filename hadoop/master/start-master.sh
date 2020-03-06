#!/bin/bash

echo "Run Master...."

#Start Services
hadoop-daemon.sh --script hdfs start namenode
#yarn-daemon.sh start resourcemanager

#Stop Services
#yarn-daemon.sh stop resourcemanager
#hadoop-daemon.sh --script hdfs stop namenode