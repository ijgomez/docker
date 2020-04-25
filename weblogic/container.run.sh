#!/bin/bash
docker run -d --name oracle-wl -p 7001:7001 -p 9002:9002 -v /home/mdc/weblogic/domain.properties:/u01/oracle/properties/domain.properties store/oracle/weblogic:12.2.1.3-dev

