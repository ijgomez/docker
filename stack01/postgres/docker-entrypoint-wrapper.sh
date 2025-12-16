#!/bin/bash
set -euo pipefail

# Si existe secret montado, exportarlo como POSTGRES_PASSWORD antes de llamar al entrypoint oficial
if [ -f "/run/secrets/postgres_password" ]; then
  export POSTGRES_PASSWORD="$(cat /run/secrets/postgres_password)"
fi

exec docker-entrypoint.sh "$@"
