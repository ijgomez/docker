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

echo "Starting stack Docker (Apache + WildFly + PostgreSQL)..."

$COMPOSE_CMD up -d --build

echo "Stack up and running!"
echo "Apache      → http://localhost"
echo "WildFly     → http://localhost:8080"
echo "WildFly Mgmt→ http://localhost:9990"
