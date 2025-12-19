#!/bin/bash
set -e

echo Create Schemas.

psql -v ON_ERROR_STOP=1 --username "template_admin" --password "template_admin" --dbname "template" <<-EOSQL

    CREATE SCHEMA template;

EOSQL

psql -v ON_ERROR_STOP=1 --username "support_admin" --password "support_admin" --dbname "support" <<-EOSQL

    CREATE SCHEMA support;

EOSQL
 