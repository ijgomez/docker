#!/bin/bash
set -e

mkdir -pv /var/lib/postgresql/data/support_data
mkdir -pv /var/lib/postgresql/data/support_index

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL

    CREATE USER support_admin with encrypted password 'support_admin';
    CREATE USER support_user with encrypted password 'support_user';

    CREATE DATABASE support;
    GRANT ALL PRIVILEGES ON DATABASE support TO support_admin;

    CREATE TABLESPACE support_data OWNER support_admin LOCATION '/var/lib/postgresql/data/support_data';
    CREATE TABLESPACE support_index OWNER support_admin LOCATION '/var/lib/postgresql/data/support_index';

EOSQL

psql -v ON_ERROR_STOP=1 --username "support_admin" --password "support_admin" --dbname "support" <<-EOSQL

    CREATE SCHEMA support;

    GRANT ALL ON SCHEMA support TO support_admin;
    GRANT USAGE ON SCHEMA support TO support_user;

    GRANT select,insert,update,delete ON ALL TABLES IN SCHEMA support TO support_user;
    GRANT execute ON ALL FUNCTIONS IN SCHEMA support TO support_user;

    GRANT usage ON ALL sequences IN SCHEMA support TO support_user;
    
EOSQL