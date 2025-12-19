#!/bin/bash
set -e

echo Create Databases.

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL

    CREATE DATABASE template;
    GRANT ALL PRIVILEGES ON DATABASE template TO template_admin;
    
    CREATE DATABASE support;
    GRANT ALL PRIVILEGES ON DATABASE support TO support_admin;

EOSQL
 