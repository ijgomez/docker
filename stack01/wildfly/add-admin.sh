#!/usr/bin/env bash
set -euo pipefail

# add-admin.sh - helper para crear un usuario de administración en el contenedor WildFly
# Uso:
#   ./add-admin.sh [-u user] [-p pass]
# Si no se proporciona contraseña, se generará una segura.

USER_NAME="${1:-}"
USER_PASS="${2:-}"

while getopts ":u:p:" opt; do
  case $opt in
    u) USER_NAME="$OPTARG" ;;
    p) USER_PASS="$OPTARG" ;;
    \?) echo "Opción inválida: -$OPTARG" >&2; exit 1 ;;
  esac
done

if [ -z "$USER_NAME" ]; then
  read -rp "Nombre de usuario (default: admin): " USER_NAME
  USER_NAME=${USER_NAME:-admin}
fi

if [ -z "$USER_PASS" ]; then
  # generar contraseña segura
  USER_PASS=$(openssl rand -base64 12)
  echo "Generada contraseña para $USER_NAME: $USER_PASS"
fi

echo "Creando usuario de gestión '$USER_NAME' en el contenedor 'wildfly'..."

docker exec -i wildfly /opt/wildfly/bin/add-user.sh -u "$USER_NAME" -p "$USER_PASS" -s -e

if [ $? -eq 0 ]; then
  echo "Usuario creado correctamente: $USER_NAME"
  echo "Contraseña: $USER_PASS"
else
  echo "Falló la creación del usuario" >&2
  exit 1
fi
