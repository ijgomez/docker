#!/bin/bash

docker run -d -p 3306:3306 --name mysql-db -e MYSQL_ROOT_PASSWORD=supersecret mysql-base
