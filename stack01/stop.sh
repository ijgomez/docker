#!/bin/bash
set -e

if command -v docker-compose >/dev/null 2>&1; then
  COMPOSE_CMD="docker-compose"
elif docker compose version >/dev/null 2>&1; then
  COMPOSE_CMD="docker compose"
else
  echo "Docker Compose is not installed"
  exit 1
fi

echo "Stoppping stack Docker..."

$COMPOSE_CMD down

echo "Stack stopped."
