#!/bin/bash
set -euo pipefail

# entrypoint.sh - añade un usuario de gestión a WildFly si se proporcionan
# variables de entorno WILDFLY_ADMIN_USER y WILDFLY_ADMIN_PASS

JBOSS_HOME=${JBOSS_HOME:-/opt/wildfly}

if [ -n "${WILDFLY_ADMIN_USER:-}" ] && [ -n "${WILDFLY_ADMIN_PASS:-}" ]; then
  MGMT_FILE="${JBOSS_HOME}/standalone/configuration/mgmt-users.properties"
  if [ ! -f "$MGMT_FILE" ]; then
    touch "$MGMT_FILE"
  fi
  if ! grep -qE "^${WILDFLY_ADMIN_USER}=" "$MGMT_FILE" 2>/dev/null; then
    echo "[entrypoint] Añadiendo usuario de gestión '${WILDFLY_ADMIN_USER}'"
    "$JBOSS_HOME/bin/add-user.sh" -u "$WILDFLY_ADMIN_USER" -p "$WILDFLY_ADMIN_PASS" -s -e || {
      echo "[entrypoint] Falló add-user.sh" >&2
      exit 1
    }
  else
    echo "[entrypoint] Usuario '${WILDFLY_ADMIN_USER}' ya existe, omitiendo creación"
  fi
else
  echo "[entrypoint] No se proporcionaron credenciales WILDFLY_ADMIN_USER/WILDFLY_ADMIN_PASS; no se crea usuario"
fi

exec "$@"
