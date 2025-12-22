#!/bin/bash
set -euo pipefail

LOG_FILE=/var/log/create-groups.log

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
    # Si existe, lo reportamos como OK
    if grep -qi "Entry already exists" "$LOG_FILE"; then
      echo "OU ya existe: $dn" | tee -a "$LOG_FILE"
    else
      echo "! Error creando OU: $dn" | tee -a "$LOG_FILE"
    fi
  fi
}

# Crear jerarquía de OUs: Groups -> Security -> Applications
create_ou "$OU_GROUPS_DN"
create_ou "$OU_SECURITY_DN"
create_ou "$OU_APPLICATIONS_DN"
create_ou "$OU_STACK02_DN"

# Grupos opcionales en OU=Applications (APP_GROUPS=G1,G2,...)
APP_GROUPS=${APP_GROUPS:-}
if [ -n "$APP_GROUPS" ]; then
  IFS=',' read -r -a groups <<< "$APP_GROUPS"
  for g in "${groups[@]}"; do
    g_trim=$(echo "$g" | xargs)
    [ -z "$g_trim" ] && continue
    echo "Creando grupo: $g_trim en $OU_APPLICATIONS_DN" | tee -a "$LOG_FILE"
    if samba-tool group add "$g_trim" --groupou "$OU_APPLICATIONS_REL" >> "$LOG_FILE" 2>&1; then
      echo "✓ Grupo creado: $g_trim" | tee -a "$LOG_FILE"
    else
      if samba-tool group show "$g_trim" >/dev/null 2>&1; then
        echo "Grupo ya existe: $g_trim" | tee -a "$LOG_FILE"
      else
        echo "! Error creando grupo: $g_trim" | tee -a "$LOG_FILE"
      fi
    fi
  done
fi

# Grupos bajo la sub-OU (por defecto "App")
APP_STACK02_GROUPS=${APP_STACK02_GROUPS:-App}
IFS=',' read -r -a subgroups <<< "$APP_STACK02_GROUPS"
for sg in "${subgroups[@]}"; do
  sg_trim=$(echo "$sg" | xargs)
  [ -z "$sg_trim" ] && continue
  echo "Creando grupo: $sg_trim en $OU_STACK02_DN" | tee -a "$LOG_FILE"
  if samba-tool group add "$sg_trim" --groupou "$OU_STACK02_REL" >> "$LOG_FILE" 2>&1; then
    echo "✓ Grupo creado: $sg_trim" | tee -a "$LOG_FILE"
  else
    if samba-tool group show "$sg_trim" >/dev/null 2>&1; then
      echo "Grupo ya existe: $sg_trim" | tee -a "$LOG_FILE"
    else
      echo "! Error creando grupo: $sg_trim" | tee -a "$LOG_FILE"
    fi
  fi
done

echo "Script de creación de OUs/grupos completado" | tee -a "$LOG_FILE"
