#!/bin/bash
set -euo pipefail

LOG_FILE=/var/log/create-users.log
USER_ID=ijgomez
PASSWORD='ijgomez_Password_2025!'

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

if samba-tool user show "$USER_ID" >/dev/null 2>&1; then
  echo "Usuario $USER_ID ya existe, no se recrea." | tee -a "$LOG_FILE"
  exit 0
fi

echo "Creando usuario $USER_ID..." | tee -a "$LOG_FILE"
success=0
for i in {1..5}; do
  echo "Intento $i: creando $USER_ID" | tee -a "$LOG_FILE"
  if samba-tool user create "$USER_ID" "$PASSWORD" \
    --given-name='Ijgomez' \
    --surname='User' \
    --mail-address='ijgomez@stack02.local' \
    >> "$LOG_FILE" 2>&1; then
    echo "✓ Usuario $USER_ID creado exitosamente" | tee -a "$LOG_FILE"
    success=1
    break
  else
    echo "! Intento $i falló, reintentando en 10s..." | tee -a "$LOG_FILE"
    sleep 10
  fi
done

if [ "$success" -ne 1 ]; then
  echo "No se pudo crear $USER_ID tras múltiples intentos" | tee -a "$LOG_FILE"
  exit 1
fi

echo "Script de creación de usuarios completado" | tee -a "$LOG_FILE"

