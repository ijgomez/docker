#!/usr/bin/env bash
set -e

# start.sh - Levanta el stack02 (reconstruye si es necesario)

if command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD="docker-compose"
elif docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD="docker compose"
else
  echo "Docker Compose no está disponible" >&2
  exit 1
fi

echo "Starting stack02 (Apache + WildFly + Elasticsearch)..."

cd "$(dirname "$0")"

$COMPOSE_CMD up -d --build

echo "stack02 up and running"
echo "Apache → http://localhost"
echo "Phpldapadmin → http://localhost/ldapadmin"
echo "WildFly → http://localhost:8080"
echo "Elasticsearch → http://localhost:9200"
