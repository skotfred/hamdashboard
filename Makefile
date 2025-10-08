.PHONY: help build run start stop restart clean logs shell ps status rebuild env network

# Variables
IMAGE_NAME = hamdashboard
CONTAINER_NAME = hamdashboard
PORT = 8091

# Default target
help:
	@echo "Ham Radio Dashboard - Docker Management"
	@echo "========================================"
	@echo ""
	@echo "Available commands:"
	@echo "  make build         - Build the Docker image"
	@echo "  make run           - Build and run with Traefik integration"
	@echo "  make start         - Start existing stopped container"
	@echo "  make stop          - Stop running container"
	@echo "  make restart       - Restart the container"
	@echo "  make rebuild       - Rebuild and restart the container"
	@echo "  make logs          - Show container logs (follow mode)"
	@echo "  make shell         - Open a shell in the running container"
	@echo "  make ps            - Show running containers"
	@echo "  make status        - Show detailed container status"
	@echo "  make network       - Create Traefik network if it doesn't exist"
	@echo "  make env           - Create .env file from example"
	@echo "  make clean         - Stop and remove container and image"
	@echo ""
	@echo "Traefik Integration:"
	@echo "  See docs/README-TRAEFIK.md for detailed configuration"
	@echo ""
	@echo "Access the dashboard at:"
	@echo "  Direct:  http://localhost:$(PORT)"
	@echo "  Traefik: http://hamdash.localhost (requires existing Traefik)"

# Create .env file from example
env:
	@if [ ! -f .env ]; then \
		echo "Creating .env file from .env.example..."; \
		cp .env.example .env; \
		echo "✓ .env file created. Please edit it with your settings."; \
	else \
		echo ".env file already exists."; \
	fi

# Create Traefik network if it doesn't exist
network:
	@echo "Checking Traefik network..."
	@docker network inspect traefik >/dev/null 2>&1 || \
		(echo "Creating Traefik network..." && docker network create traefik)
	@echo "✓ Traefik network ready"

# Build the Docker image
build:
	@echo "Building Docker image..."
	docker compose build

# Build and run with Traefik integration (requires existing Traefik)
run: network
	@if [ ! -f .env ]; then \
		echo "⚠ No .env file found. Creating from example..."; \
		cp .env.example .env; \
		echo "Please edit .env with your settings, then run 'make run' again."; \
		exit 1; \
	fi
	@echo "Starting Ham Radio Dashboard with Traefik integration..."
	docker compose up -d
	@echo ""
	@echo "✓ Dashboard is running"
	@echo "  Traefik URL: http://$$(grep HAMDASH_DOMAIN .env | cut -d '=' -f2)"
	@echo "  Direct URL:  http://localhost:$(PORT)"

# Start existing stopped container
start:
	@echo "Starting container..."
	docker compose start
	@echo "✓ Container started"

# Stop running container
stop:
	@echo "Stopping container..."
	docker compose stop
	@echo "✓ Container stopped"

# Restart the container
restart:
	@echo "Restarting container..."
	docker compose restart
	@echo "✓ Container restarted"

# Rebuild and restart
rebuild:
	@echo "Rebuilding and restarting container..."
	docker compose up -d --build
	@echo "✓ Container rebuilt and restarted"

# Show logs
logs:
	@echo "Showing container logs (Ctrl+C to exit)..."
	docker compose logs -f

# Open shell in container
shell:
	@echo "Opening shell in container..."
	docker exec -it $(CONTAINER_NAME) /bin/sh

# Show running containers
ps:
	@echo "Running containers:"
	docker compose ps

# Show detailed status
status:
	@echo "Container status:"
	@docker ps -a --filter "name=$(CONTAINER_NAME)" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Clean up everything
clean:
	@echo "Stopping and removing container..."
	docker compose down
	@echo "Removing Docker image..."
	docker rmi $(IMAGE_NAME) 2>/dev/null || true
	@echo "✓ Cleanup complete"


