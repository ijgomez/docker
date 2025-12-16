#!/usr/bin/env bash
set -euo pipefail

# stop-containers.sh - Para contenedores sin eliminarlos
# Uso: ./stop-containers.sh [servicio1 servicio2 ...]

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
  echo "Parando todos los contenedores del stack (sin eliminarlos)..."
  $COMPOSE_CMD stop
else
  echo "Parando servicios: ${SERVICES[*]}"
  $COMPOSE_CMD stop "${SERVICES[@]}"
fi

echo "Operación completada. Usa '$COMPOSE_CMD ps' para ver el estado."
