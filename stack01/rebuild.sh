#!/usr/bin/env bash
set -euo pipefail

# rebuild.sh - reconstruye imágenes del stack y levanta los contenedores
# Uso: ./rebuild.sh [servicio1 servicio2 ...]
# Si no se pasan servicios, reconstruye y levanta todo el stack.

# Ensure script is executable on creation
chmod +x "$0" 2>/dev/null || true

if command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD="docker-compose"
elif docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD="docker compose"
else
  echo "ERROR: Docker Compose no está disponible (neither docker-compose nor docker compose)."
  exit 1
fi

SERVICES=("$@")

echo "Reconstruyendo imágenes y levantando servicios..."

if [ ${#SERVICES[@]} -eq 0 ]; then
  # rebuild all and bring up
  $COMPOSE_CMD up -d --build
else
  # rebuild only listed services and bring them up
  for s in "${SERVICES[@]}"; do
    echo "Reconstruyendo servicio: $s"
    $COMPOSE_CMD build --pull --no-cache "$s"
  done
  $COMPOSE_CMD up -d "${SERVICES[@]}"
fi

echo "Hecho. Contenedores en ejecución:"
$COMPOSE_CMD ps

echo
echo "Comandos útiles:
- Ver logs: $COMPOSE_CMD logs -f
- Reconstruir sólo wildfly: $0 wildfly
- Forzar recreación (sin cache): $COMPOSE_CMD up -d --build --force-recreate"
