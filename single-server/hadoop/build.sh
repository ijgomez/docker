#!/bin/bash

set -e

docker build -t hadoop-base:latest ./base
docker build -t hadoop-base:latest ./master
docker build -t hadoop-base:latest ./slave
