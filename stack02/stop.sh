#!/usr/bin/env bash
set -e

# stop.sh - Para y elimina el stack02 (down)

if command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD="docker-compose"
elif docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD="docker compose"
else
  echo "Docker Compose no está disponible" >&2
  exit 1
fi

echo "Stopping stack02..."

cd "$(dirname "$0")"

$COMPOSE_CMD down --volumes

echo "stack02 stopped." 
