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

# Si el módulo de Postgres existe, arrancar WildFly en modo admin-only para
# registrar el driver JDBC en el subsystem de datasources (no falla si ya existe).
PG_MODULE_DIR="${JBOSS_HOME}/modules/system/layers/base/org/postgresql/main"
PG_JAR="${PG_MODULE_DIR}/postgresql-42.6.0.jar"
if [ -f "$PG_JAR" ]; then
  echo "[entrypoint] PostgreSQL module encontrado, comprobando registro del driver JDBC..."

  # Arrancar en admin-only en background
  "$JBOSS_HOME/bin/standalone.sh" -b 0.0.0.0 -bmanagement 0.0.0.0 --admin-only &

  # Esperar a que la interfaz de management esté disponible
  for i in $(seq 1 30); do
    if "$JBOSS_HOME/bin/jboss-cli.sh" --connect ":read-attribute(name=server-state)" >/dev/null 2>&1; then
      break
    fi
    sleep 1
  done

  # Intentar añadir el driver (si ya existe, el comando puede fallar y lo ignoramos)
  "$JBOSS_HOME/bin/jboss-cli.sh" --connect --commands="/subsystem=datasources/jdbc-driver=postgresql:add(driver-name=postgresql,driver-module-name=org.postgresql,driver-class-name=org.postgresql.Driver)" || true

  # Recargar y apagar el servidor admin-only para que el proceso de inicio normal continúe
  "$JBOSS_HOME/bin/jboss-cli.sh" --connect --commands=":reload" || true
  "$JBOSS_HOME/bin/jboss-cli.sh" --connect --commands=":shutdown" || true
fi

exec "$@"

