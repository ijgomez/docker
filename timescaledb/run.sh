#!/bin/bash

set -e

docker run -d --name timescaledb -p 5432:5432 -e POSTGRES_PASSWORD=password timescaledb-base:latest