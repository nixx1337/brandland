#!/bin/bash
# BrandLand deploy script for your server
# Copy this to /opt/brandland/deploy.sh and run: bash deploy.sh

set -e

echo "=== BrandLand Deploy ==="

# Pull latest changes (if using git)
# git pull origin main

# Rebuild and restart
echo "[1/3] Building image..."
docker compose build --no-cache

echo "[2/3] Stopping old container..."
docker compose down

echo "[3/3] Starting new container..."
docker compose up -d

# Cleanup old images
docker image prune -f

echo ""
echo "=== Deploy complete! ==="
echo "Site running at: http://localhost:8080"
echo ""
echo "Check status: docker compose ps"
echo "View logs:    docker compose logs -f brandland"
