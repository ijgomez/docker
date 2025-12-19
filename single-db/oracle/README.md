# Docker: Run Oracle Database

Download Image: `download.image.sh`

Container Run: `container.run.sh`

Container Stop: `container.stop.sh`

The Database is created with the default password `Oradoc_db1`, to change the database password you must use sqlplus.  To run sqlplus pull the Oracle Instant Client from the Oracle Container Registry or the Docker Store, and run a sqlplus container with the following command:

`$ docker run -ti --network=SampleNET --rm store/oracle/database-instantclient:12.2.0.1 sqlplus sys/Oradoc_db1@InfraDB:1521/InfraDB.us.oracle.com AS SYSDBA`

Change system password: `SQL> alter user system identified by MYDBPasswd container=all;`

To run the DDL that creates the tables needed by the application, copy createSchema.sql into the Database container

`$ docker cp createSchema.sql InfraDB:/u01/app/oracle`
Run sqlplus to run the DDL

`$docker exec -ti InfraDB /u01/app/oracle/product/12.2.0/dbhome_1/bin/sqlplus system/MYDBPasswd@InfraDB:1521/InfraPDB1.us.orac`