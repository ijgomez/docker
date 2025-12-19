#!/bin/bash
set -e

echo Create Tablespace.

mkdir -pv /var/lib/postgresql/data/template_data
mkdir -pv /var/lib/postgresql/data/template_index
mkdir -pv /var/lib/postgresql/data/support_data
mkdir -pv /var/lib/postgresql/data/support_index

echo "$USER"

#chown postgres:root /var/lib/postgresql/data/template_data
#chown postgres:root /var/lib/postgresql/data/template_index
#chown postgres:root /var/lib/postgresql/data/support_data
#chown postgres:root /var/lib/postgresql/data/support_index

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL

    CREATE TABLESPACE template_data OWNER template_admin LOCATION '/var/lib/postgresql/data/template_data';
    CREATE TABLESPACE template_index OWNER template_admin LOCATION '/var/lib/postgresql/data/template_index';
    CREATE TABLESPACE support_data OWNER support_admin LOCATION '/var/lib/postgresql/data/support_data';
    CREATE TABLESPACE support_index OWNER support_admin LOCATION '/var/lib/postgresql/data/support_index';

EOSQL
 