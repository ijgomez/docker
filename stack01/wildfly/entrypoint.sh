#!/bin/bash
set -euo pipefail

# entrypoint.sh - añade un usuario de gestión a WildFly si se proporcionan
# variables de entorno WILDFLY_ADMIN_USER y WILDFLY_ADMIN_PASS

JBOSS_HOME=${JBOSS_HOME:-/opt/wildfly}

# Función helper para ejecutar comandos como el usuario 'wildfly'
run_as_wildfly() {
  if command -v runuser >/dev/null 2>&1; then
    runuser -u wildfly -- "$@"
  else
    su -s /bin/sh -c "$*" wildfly
  fi
}

# Si el entrypoint se ejecuta como root, asegurar que los directorios persistentes
# existen, tienen permisos adecuados y son propiedad del usuario 'wildfly'. Esto
# corrige casos en los que volúmenes montados son creados por root y WildFly
# (ejecutándose como 'wildfly') no puede escribir en ellos.
if [ "$(id -u)" = "0" ]; then
  for d in "${JBOSS_HOME}/standalone/log" "${JBOSS_HOME}/standalone/tmp" "${JBOSS_HOME}/standalone/data"; do
    if [ ! -d "$d" ]; then
      mkdir -p "$d"
    fi
    chown -R wildfly:wildfly "$d" || true
    chmod 0775 "$d" || true
  done
fi

# Leer secrets si están montados en /run/secrets (Docker Swarm / Docker secrets)
if [ -f "/run/secrets/wildfly_admin_password" ]; then
  export WILDFLY_ADMIN_PASS=$(cat /run/secrets/wildfly_admin_password)
fi
if [ -f "/run/secrets/postgres_password" ]; then
  export DB_PASS=$(cat /run/secrets/postgres_password)
fi

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

  # Arrancar en admin-only en background como usuario 'wildfly'
  run_as_wildfly "$JBOSS_HOME/bin/standalone.sh" -b 0.0.0.0 -bmanagement 0.0.0.0 --admin-only &

  # Esperar a que la interfaz de management esté disponible
  for i in $(seq 1 30); do
    if run_as_wildfly "$JBOSS_HOME/bin/jboss-cli.sh" --connect ":read-attribute(name=server-state)" >/dev/null 2>&1; then
      break
    fi
    sleep 1
  done

  # Intentar añadir el driver (si ya existe, el comando puede fallar y lo ignoramos)
  run_as_wildfly "$JBOSS_HOME/bin/jboss-cli.sh" --connect --commands="/subsystem=datasources/jdbc-driver=postgresql:add(driver-name=postgresql,driver-module-name=org.postgresql,driver-class-name=org.postgresql.Driver)" || true
  # Crear datasource Postgres si no existe (ejecutar en admin-only)
  DS_NAME="PostgresDS"
  DB_HOST=${DB_HOST:-postgres}
  DB_NAME=${DB_NAME:-appdb}
  DB_USER=${DB_USER:-appuser}
  DB_PASS=${DB_PASS:-apppass}
  JNDI_NAME=${JNDI_NAME:-java:/PostgresDS}

  if ! run_as_wildfly "$JBOSS_HOME/bin/jboss-cli.sh" --connect --commands="/subsystem=datasources/data-source=${DS_NAME}:read-resource" >/dev/null 2>&1; then
    echo "[entrypoint] Datasource ${DS_NAME} no existe. Creando apuntando a ${DB_HOST}/${DB_NAME}..."
    CMD_ADD_DS="/subsystem=datasources/data-source=${DS_NAME}:add(jndi-name=${JNDI_NAME},driver-name=postgresql,connection-url=jdbc:postgresql://${DB_HOST}:5432/${DB_NAME},user-name=${DB_USER},password=${DB_PASS},max-pool-size=20,min-pool-size=1,enabled=true,background-validation=true,background-validation-millis=30000,check-valid-connection-sql='SELECT 1',valid-connection-checker-class-name=org.jboss.jca.adapters.jdbc.extensions.postgres.PostgreSQLValidConnectionChecker,exception-sorter-class-name=org.jboss.jca.adapters.jdbc.extensions.postgres.PostgreSQLExceptionSorter)"
    run_as_wildfly "$JBOSS_HOME/bin/jboss-cli.sh" --connect --commands="$CMD_ADD_DS" || true
    echo "[entrypoint] Datasource ${DS_NAME} creado (o ya existía)."
  else
    echo "[entrypoint] Datasource ${DS_NAME} ya existe."
  fi

  # Recargar y apagar el servidor admin-only para que el proceso de inicio normal continúe
  run_as_wildfly "$JBOSS_HOME/bin/jboss-cli.sh" --connect --commands=":reload" || true
  run_as_wildfly "$JBOSS_HOME/bin/jboss-cli.sh" --connect --commands=":shutdown" || true
fi
if [ "$(id -u)" = "0" ]; then
  # Si entramos como root, ejecutar el servidor final como user 'wildfly'
  exec runuser -u wildfly -- "$@"
else
  exec "$@"
fi

