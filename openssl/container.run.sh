#!/bin/bash
docker run -it --name openssl -v "$PWD":/workspace --entrypoint /bin/ash openssl-base:latest