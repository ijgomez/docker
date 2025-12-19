# Docker: Run Weblogic Cluster

Run: `docker run -d --name oracle-wl -p 7001:7001 -p 9002:9002 -v ${PWD}:/u01/oracle/properties container-registry.oracle.com/middleware/weblogic:12.2.1.3`

Linux: `$PWD`
Windows PowerShell: `${PWD}`

URL of Administration: [Link](http://localhost:9002/console)


Reference:

https://container-registry.oracle.com/pls/apex/f?p=113:4:10575610643973::NO:4:P4_REPOSITORY,AI_REPOSITORY,AI_REPOSITORY_NAME,P4_REPOSITORY_NAME,P4_EULA_ID,P4_BUSINESS_AREA_ID:5,5,Oracle%20WebLogic%20Server,Oracle%20WebLogic%20Server,1,0&cs=3iFxObG0_85t6Mwsgvrw2P_fEEhpBvA5Xa1miqkzR5rgb_0syeP27K3AbcxwbL500SJ3mjVxwJjiAfxTadMKqxA
