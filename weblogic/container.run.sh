#!/bin/bash
docker run -d --name oracle-wl -p 7001:7001 -p 9002:9002 -it  -v /apps/docker/oracle-wl:/u01/oracle/properties container-registry.oracle.com/middleware/weblogic:12.2.1.4

