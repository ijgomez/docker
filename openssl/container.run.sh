#!/bin/bash
docker run -it --name openssl -v ssl:/workspace --entrypoint /bin/ash openssl-base:latest