#!/bin/bash
set -e

echo Create Users.

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL

    CREATE USER template_admin with encrypted password 'template_admin';
    CREATE USER template_user with encrypted password 'template_user';
    CREATE USER support_admin with encrypted password 'support_admin';
    CREATE USER support_user with encrypted password 'support_user';

EOSQL