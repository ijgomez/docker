#!/bin/bash
docker run -d -it --name ora122 -P --env-file ora.conf container-registry.oracle.com/database/enterprise:12.2.0.1

