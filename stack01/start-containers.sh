#!/usr/bin/env bash
set -euo pipefail

# start-containers.sh - Inicia los contenedores ya creados sin recrearlos
# Uso: ./start-containers.sh [servicio1 servicio2 ...]

# Ensure executable bit
chmod +x "$0" 2>/dev/null || true

if command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD="docker-compose"
elif docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD="docker compose"
else
  echo "ERROR: Docker Compose no está disponible." >&2
  exit 1
fi

SERVICES=("$@")

if [ ${#SERVICES[@]} -eq 0 ]; then
  echo "Iniciando todos los contenedores existentes..."
  $COMPOSE_CMD start
else
  echo "Iniciando servicios: ${SERVICES[*]}"
  $COMPOSE_CMD start "${SERVICES[@]}"
fi

echo "Operación completada. Usa '$COMPOSE_CMD ps' para ver el estado."
