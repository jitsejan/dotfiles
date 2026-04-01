#!/usr/bin/env bash
set -e

echo "🐳 Setting up Docker..."

# Check if Docker Desktop is installed
if [[ ! -d "/Applications/Docker.app" ]]; then
  echo "❌ Docker.app not found. Please install it first with 'brew install --cask docker-desktop'"
  exit 1
fi

echo "✅ Docker Desktop found"

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
  echo "🚀 Starting Docker Desktop..."
  open -a Docker
  
  echo "⏳ Waiting for Docker to start..."
  # Wait up to 60 seconds for Docker to start
  for i in {1..12}; do
    if docker info >/dev/null 2>&1; then
      break
    fi
    echo "   Still waiting... ($((i*5))s)"
    sleep 5
  done
  
  if ! docker info >/dev/null 2>&1; then
    echo "⚠️  Docker may take longer to start. Please check Docker Desktop manually."
    echo "   You can verify it's running with: docker --version"
    exit 0
  fi
fi

echo "✅ Docker is running"

# Verify Docker and docker-compose are available
DOCKER_VERSION=$(docker --version 2>/dev/null || echo "Not available")
COMPOSE_VERSION=$(docker compose version 2>/dev/null || echo "Not available")

echo "📋 Docker installation summary:"
echo "   Docker: $DOCKER_VERSION"
echo "   Docker Compose: $COMPOSE_VERSION"

# Basic configuration recommendations
echo ""
echo "💡 Docker setup recommendations:"
echo "   • Configure resource limits in Docker Desktop settings"
echo "   • Enable Kubernetes if needed (Docker Desktop > Settings > Kubernetes)"
echo "   • Consider setting up Docker Hub authentication: docker login"

echo "✅ Docker setup complete!"
echo "💡 You can now use 'docker' and 'docker compose' commands"