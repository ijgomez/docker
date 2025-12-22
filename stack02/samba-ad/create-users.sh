#!/bin/bash
set -euo pipefail

LOG_FILE=/var/log/create-users.log
CSV_FILE=${USERS_CSV_FILE:-/usr/local/etc/users.csv}

# Derivar DC=... desde DOMAIN
DOMAIN_FQDN=${DOMAIN:-stack02.local}
DOMAIN_DN=$(echo "$DOMAIN_FQDN" | awk -F. '{printf "DC=%s,DC=%s", $1, $2}')

echo "Esperando que Samba AD se inicialice..." | tee -a "$LOG_FILE"
for i in $(seq 1 30); do
  if samba-tool user list >/dev/null 2>&1; then
    echo "Samba AD listo (intento $i)" | tee -a "$LOG_FILE"
    break
  fi
  echo "Aún no listo, reintentando en 10s... (intento $i/30)" | tee -a "$LOG_FILE"
  sleep 10
done

if ! samba-tool user list >/dev/null 2>&1; then
  echo "Samba AD no respondió, abortando creación de usuarios." | tee -a "$LOG_FILE"
  exit 1
fi

# Asegurar que los grupos de Apps existen (App y App_Users) antes de añadir miembros
ensure_group() {
  local dn="$1"
  local name
  name=$(echo "$dn" | sed -n 's/^[cC][nN]=\([^,]*\).*/\1/p')
  [ -z "$name" ] && return
  if ! samba-tool group show "$name" >/dev/null 2>&1; then
    echo "Creando grupo faltante $name (DN: $dn)" | tee -a "$LOG_FILE"
    samba-tool group add "$name" --groupou "OU=Applications,OU=Security,OU=Groups" >> "$LOG_FILE" 2>&1 || true
  fi
}

ensure_group "CN=App,OU=Stack02,OU=Applications,OU=Security,OU=Groups,$DOMAIN_DN"
ensure_group "CN=App_Users,OU=Applications,OU=Security,OU=Groups,$DOMAIN_DN"

if [ ! -f "$CSV_FILE" ]; then
  echo "Archivo CSV no encontrado: $CSV_FILE" | tee -a "$LOG_FILE"
  exit 1
fi

# Leer CSV línea por línea (saltando cabecera)
tail -n +2 "$CSV_FILE" | while IFS=';' read -r userId password displayName name mail memberOf; do
  # Trim espacios
  userId=$(echo "$userId" | xargs)
  password=$(echo "$password" | xargs)
  displayName=$(echo "$displayName" | xargs)
  name=$(echo "$name" | xargs)
  mail=$(echo "$mail" | xargs)
  memberOf=$(echo "$memberOf" | xargs)

  [ -z "$userId" ] && continue

  if samba-tool user show "$userId" >/dev/null 2>&1; then
    echo "Usuario $userId ya existe, omitiendo." | tee -a "$LOG_FILE"
    continue
  fi

  echo "Creando usuario $userId..." | tee -a "$LOG_FILE"
  success=0
  for i in {1..5}; do
    echo "Intento $i: creando $userId" | tee -a "$LOG_FILE"
    if samba-tool user create "$userId" "$password" \
      --given-name="$name" \
      --surname='User' \
      --mail-address="$mail" \
      >> "$LOG_FILE" 2>&1; then
      echo "✓ Usuario $userId creado exitosamente" | tee -a "$LOG_FILE"
      success=1
      break
    else
      echo "! Intento $i falló, reintentando en 10s..." | tee -a "$LOG_FILE"
      sleep 10
    fi
  done

  if [ "$success" -ne 1 ]; then
    echo "No se pudo crear $userId tras múltiples intentos" | tee -a "$LOG_FILE"
    continue
  fi

  # Añadir usuario a grupos si memberOf está definido (soporta múltiples DN separados por '|')
  if [ -n "$memberOf" ]; then
    IFS='|' read -r -a groups <<< "$memberOf"
    for dn in "${groups[@]}"; do
      dn_trim=$(echo "$dn" | xargs)
      [ -z "$dn_trim" ] && continue
      groupName=$(echo "$dn_trim" | sed -n 's/^[cC][nN]=\([^,]*\).*/\1/p')
      if [ -n "$groupName" ]; then
        echo "Añadiendo $userId al grupo $groupName (DN: $dn_trim)..." | tee -a "$LOG_FILE"
        if samba-tool group addmembers "$groupName" "$userId" >> "$LOG_FILE" 2>&1; then
          echo "✓ Usuario $userId añadido al grupo $groupName" | tee -a "$LOG_FILE"
        else
          echo "! Error añadiendo $userId al grupo $groupName" | tee -a "$LOG_FILE"
        fi
      fi
    done
  fi
done

echo "Script de creación de usuarios completado" | tee -a "$LOG_FILE"

