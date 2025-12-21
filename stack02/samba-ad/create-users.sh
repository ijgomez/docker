#!/bin/bash

# Script para crear usuarios en Samba AD al arrancar
# Se ejecuta dentro del contenedor después de que Samba AD esté listo

# Esperar a que Samba AD esté completamente inicializado (más tiempo)
echo "Esperando que Samba AD se inicialice..."
sleep 120

# Variables
DOMAIN="stack02.local"
DOMAINDN="dc=stack02,dc=local"
ADMIN_PASS="${DOMAINPASS:-Admin_Password_2025!}"

# Crear usuario ijgomez
echo "Creando usuario ijgomez en $DOMAIN..."

for i in {1..5}; do
  echo "Intento $i: Creando usuario ijgomez..."
  samba-tool user create ijgomez --password='ijgomez_Password_2025!' \
    --given-name='Ijgomez' \
    --surname='User' \
    --mail-address='ijgomez@stack02.local' \
    --use-kerberos=required \
    --must-change-password=0 \
    2>&1 | tee -a /var/log/create-users.log
  
  if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "✓ Usuario ijgomez creado exitosamente"
    break
  else
    echo "! Intento $i falló, reintentando en 10s..."
    sleep 10
  fi
done

echo "Script de creación de usuarios completado"

