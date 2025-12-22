#!/bin/bash
set -euo pipefail

LOG_FILE=/var/log/create-groups.log
CSV_FILE=${GROUPS_CSV_FILE:-/usr/local/etc/groups.csv}

# Derivar DC=... desde DOMAIN (p.ej. stack02.local -> DC=stack02,DC=local)
DOMAIN_FQDN=${DOMAIN:-stack02.local}
DOMAIN_DN=$(echo "$DOMAIN_FQDN" | awk -F. '{printf "DC=%s,DC=%s", $1, $2}')

# DN completos para creación de OUs
OU_GROUPS_DN="OU=Groups,$DOMAIN_DN"
OU_SECURITY_DN="OU=Security,OU=Groups,$DOMAIN_DN"
OU_APPLICATIONS_DN="OU=Applications,OU=Security,OU=Groups,$DOMAIN_DN"

# Rutas relativas (sin DC=...) para creación de grupos con --groupou
OU_APPLICATIONS_REL="OU=Applications,OU=Security,OU=Groups"

# Sub-OU bajo Applications y grupos específicos
SUB_OU_NAME=${APP_SUB_OU_NAME:-Stack02}
OU_STACK02_DN="OU=${SUB_OU_NAME},${OU_APPLICATIONS_DN}"
OU_STACK02_REL="OU=${SUB_OU_NAME},${OU_APPLICATIONS_REL}"

echo "Esperando que Samba AD esté listo para crear OUs/grupos..." | tee -a "$LOG_FILE"
for i in $(seq 1 30); do
  if samba-tool user list >/dev/null 2>&1; then
    echo "Samba AD listo (intento $i)" | tee -a "$LOG_FILE"
    break
  fi
  echo "Aún no listo, reintentando en 10s... (intento $i/30)" | tee -a "$LOG_FILE"
  sleep 10
done

if ! samba-tool user list >/dev/null 2>&1; then
  echo "Samba AD no respondió, abortando creación de OUs/grupos." | tee -a "$LOG_FILE"
  exit 1
fi

create_ou() {
  local dn="$1"
  echo "Creando OU: $dn" | tee -a "$LOG_FILE"
  if samba-tool ou create "$dn" >> "$LOG_FILE" 2>&1; then
    echo "✓ OU creada: $dn" | tee -a "$LOG_FILE"
  else
    if samba-tool ou list | grep -qi "^${dn}$"; then
      echo "OU ya existe: $dn" | tee -a "$LOG_FILE"
    else
      echo "! Error creando OU: $dn" | tee -a "$LOG_FILE"
    fi
  fi
}

strip_domain_suffix() {
  local dn="$1"
  local suffix=",$DOMAIN_DN"
  local dn_lower
  local suffix_lower
  dn_lower=$(echo "$dn" | tr '[:upper:]' '[:lower:]')
  suffix_lower=$(echo "$suffix" | tr '[:upper:]' '[:lower:]')
  if [[ "$dn_lower" == *"$suffix_lower" ]]; then
    local trim_len=$(( ${#dn} - ${#suffix} ))
    echo "${dn:0:trim_len}"
  else
    echo "$dn"
  fi
}

create_group() {
  local name="$1"
  local ou_rel="$2"
  local description="$3"

  [ -z "$name" ] && return

  local ou_dn="$ou_rel,$DOMAIN_DN"
  create_ou "$ou_dn"

  echo "Creando grupo: $name en $ou_dn" | tee -a "$LOG_FILE"
  local cmd=(samba-tool group add "$name" --groupou "$ou_rel")
  if [ -n "$description" ]; then
    cmd+=("--description=$description")
  fi

  if "${cmd[@]}" >> "$LOG_FILE" 2>&1; then
    echo "✓ Grupo creado: $name" | tee -a "$LOG_FILE"
  else
    if samba-tool group show "$name" >/dev/null 2>&1; then
      echo "Grupo ya existe: $name" | tee -a "$LOG_FILE"
    else
      echo "! Error creando grupo: $name" | tee -a "$LOG_FILE"
    fi
  fi
}

# Crear jerarquía de OUs: Groups -> Security -> Applications
create_ou "$OU_GROUPS_DN"
create_ou "$OU_SECURITY_DN"
create_ou "$OU_APPLICATIONS_DN"
create_ou "$OU_STACK02_DN"

# Procesar grupos desde CSV si existe; en caso contrario, usar variables existentes
if [ -f "$CSV_FILE" ] && [ -s "$CSV_FILE" ]; then
  echo "Procesando grupos desde CSV: $CSV_FILE" | tee -a "$LOG_FILE"
  tail -n +2 "$CSV_FILE" | while IFS=';' read -r name ou description; do
    name=$(echo "$name" | xargs)
    ou=$(echo "$ou" | xargs)
    description=$(echo "$description" | xargs)

    [ -z "$name" ] && continue

    if [ -z "$ou" ]; then
      ou_rel="$OU_STACK02_REL"
    else
      ou_rel=$(strip_domain_suffix "$ou")
    fi

    create_group "$name" "$ou_rel" "$description"
  done
else
  echo "CSV de grupos no encontrado o vacío, usando variables de entorno" | tee -a "$LOG_FILE"

  # Grupos opcionales en OU=Applications (APP_GROUPS=G1,G2,...)
  APP_GROUPS=${APP_GROUPS:-}
  if [ -n "$APP_GROUPS" ]; then
    IFS=',' read -r -a groups <<< "$APP_GROUPS"
    for g in "${groups[@]}"; do
      g_trim=$(echo "$g" | xargs)
      [ -z "$g_trim" ] && continue
      create_group "$g_trim" "$OU_APPLICATIONS_REL" ""
    done
  fi

  # Grupos bajo la sub-OU (por defecto "App")
  APP_STACK02_GROUPS=${APP_STACK02_GROUPS:-App}
  IFS=',' read -r -a subgroups <<< "$APP_STACK02_GROUPS"
  for sg in "${subgroups[@]}"; do
    sg_trim=$(echo "$sg" | xargs)
    [ -z "$sg_trim" ] && continue
    create_group "$sg_trim" "$OU_STACK02_REL" ""
  done
fi

echo "Script de creación de OUs/grupos completado" | tee -a "$LOG_FILE"
