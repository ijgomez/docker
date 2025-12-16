#!/usr/bin/env bash
set -euo pipefail

# rebuild.sh - Reconstruye imágenes y levanta los servicios de stack02
# Uso: ./rebuild.sh [servicio1 servicio2 ...]

if command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD="docker-compose"
elif docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD="docker compose"
else
  echo "ERROR: Docker Compose no está disponible." >&2
  exit 1
fi

cd "$(dirname "$0")"

SERVICES=("$@")

echo "Reconstruyendo imágenes y levantando servicios..."

if [ ${#SERVICES[@]} -eq 0 ]; then
  $COMPOSE_CMD up -d --build
else
  for s in "${SERVICES[@]}"; do
    echo "Reconstruyendo servicio: $s"
    $COMPOSE_CMD build --pull --no-cache "$s"
  done
  $COMPOSE_CMD up -d "${SERVICES[@]}"
fi

echo "Operación completada. Usa '$COMPOSE_CMD ps' para ver el estado." 
