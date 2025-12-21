#!/usr/bin/env bash
set -euo pipefail

# clean.sh
# Script to free Docker resources: images, containers, networks, volumes, build and builder cache.
# Usage: ./clean.sh [-y]
#   -y  : auto-confirm and run without interactive prompt

AUTO_CONFIRM=0
while getopts "y" opt; do
  case "$opt" in
    y) AUTO_CONFIRM=1 ;;
    *) echo "Usage: $0 [-y]"; exit 1 ;;
  esac
done

if ! command -v docker >/dev/null 2>&1; then
  echo "docker command not found. Install Docker and try again." >&2
  exit 2
fi

  echo
  # Detect docker-compose files and bring down projects (if any)
  COMPOSE_FILES=$(find . -maxdepth 4 -type f \( -name "docker-compose.yml" -o -name "docker-compose.yaml" \) 2>/dev/null || true)
  if [ -n "$COMPOSE_FILES" ]; then
    echo "Detected docker-compose files:" 
    echo "$COMPOSE_FILES"
    if [ "$AUTO_CONFIRM" -ne 1 ]; then
      read -r -p "Bring down these compose projects (docker compose down --rmi all --volumes)? [y/N] " REPLY2
      case "$REPLY2" in
        [yY]|[yY][eE][sS]) ;;
        *) echo "Skipping docker compose down."; COMPOSE_FILES="" ;;
      esac
    fi
  fi

  if [ -n "$COMPOSE_FILES" ]; then
    echo "Bringing down compose projects..."
    # iterate unique directories containing compose files
    echo "$COMPOSE_FILES" | while IFS= read -r f; do
      dir=$(dirname "$f")
      echo "--> docker compose down in: $dir"
      (cd "$dir" && docker compose down --rmi all --volumes) || true
    done
  fi

  echo "1) Prune system (images, containers, networks, build cache and volumes)"
echo

if [ "$AUTO_CONFIRM" -ne 1 ]; then
  read -r -p "Proceed and remove unused images/containers/networks/volumes and builder cache? [y/N] " REPLY
  case "$REPLY" in
    [yY]|[yY][eE][sS]) ;;
    *) echo "Aborted by user."; exit 0 ;;
  esac
fi

echo "1) Prune system (images, containers, networks, build cache and volumes)"
docker system prune -a --volumes -f || true

echo "2) Prune builder cache"
docker builder prune -af || true

echo "3) If buildx is available, remove buildx builders and prune buildx cache"
if docker buildx version >/dev/null 2>&1; then
  # try to remove builders (no-op if none)
  if docker buildx ls 2>/dev/null | sed -n '2,$p' | sed '/^$/d' | grep -q .; then
    echo "Removing buildx builders (may show errors if builder in use)"
    docker buildx rm --all || true
  fi
  docker buildx prune -af || true
fi

echo "4) Extra safety prunes (images, networks, volumes)"
docker image prune -af || true
docker network prune -f || true
docker volume prune -f || true

echo
echo "Docker cleanup completed. You may want to run 'docker system df' to verify freed space."
echo "Make the script executable with: chmod +x clean.sh"
