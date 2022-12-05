#!/bin/bash
set -e

echo Create Grants.

psql -v ON_ERROR_STOP=1 --username "template_admin" --password "template_admin" --dbname "template" <<-EOSQL

    GRANT ALL ON SCHEMA template TO template_admin;
    GRANT USAGE ON SCHEMA template TO template_user;

    GRANT select,insert,update,delete ON ALL TABLES IN SCHEMA template TO template_user;
    GRANT execute ON ALL FUNCTIONS IN SCHEMA template TO template_user;

    GRANT usage ON ALL sequences IN SCHEMA template TO template_user;

EOSQL

psql -v ON_ERROR_STOP=1 --username "support_admin" --password "support_admin" --dbname "support" <<-EOSQL

    GRANT ALL ON SCHEMA support TO support_admin;
    GRANT USAGE ON SCHEMA support TO support_user;

    GRANT select,insert,update,delete ON ALL TABLES IN SCHEMA support TO support_user;
    GRANT execute ON ALL FUNCTIONS IN SCHEMA support TO support_user;

    GRANT usage ON ALL sequences IN SCHEMA support TO support_user;
    
EOSQL
 