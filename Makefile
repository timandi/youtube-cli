.PHONY: help build run stop clean test logs shell push

# Variables
IMAGE_NAME := youtube-remote
IMAGE_TAG := latest
CONTAINER_NAME := youtube-remote-mcp
REGISTRY ?= docker.io

# Default target
help:
	@echo "YouTube Remote MCP Server - Docker Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  build       - Build Docker image"
	@echo "  run         - Run container with docker-compose"
	@echo "  stop        - Stop and remove containers"
	@echo "  clean       - Remove containers, images, and volumes"
	@echo "  logs        - Show container logs"
	@echo "  shell       - Open shell in running container"
	@echo "  test        - Test the Docker build"
	@echo "  push        - Push image to registry"
	@echo "  dev         - Run in development mode with source mount"

# Build the Docker image
build:
	@echo "Building Docker image..."
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .

# Build without cache
build-no-cache:
	@echo "Building Docker image (no cache)..."
	docker build --no-cache -t $(IMAGE_NAME):$(IMAGE_TAG) .

# Run with docker-compose
run:
	@echo "Starting YouTube Remote MCP server..."
	docker-compose up -d

# Run in foreground
run-fg:
	@echo "Starting YouTube Remote MCP server (foreground)..."
	docker-compose up

# Run in development mode (with source code mount)
dev:
	@echo "Starting in development mode..."
	docker-compose -f docker-compose.yml -f docker-compose.dev.yml up

# Stop containers
stop:
	@echo "Stopping containers..."
	docker-compose down

# View logs
logs:
	docker-compose logs -f

# Open shell in running container
shell:
	docker exec -it $(CONTAINER_NAME) /bin/bash

# Open Python shell in container
python-shell:
	docker exec -it $(CONTAINER_NAME) python

# Test the build
test:
	@echo "Testing Docker build..."
	docker run --rm $(IMAGE_NAME):$(IMAGE_TAG) python -c "from remote import YouTubeRemote; print('Build test passed!')"

# Clean up containers
clean-containers:
	@echo "Removing containers..."
	docker-compose down -v

# Clean up images
clean-images:
	@echo "Removing images..."
	docker rmi $(IMAGE_NAME):$(IMAGE_TAG) || true

# Clean everything
clean: clean-containers clean-images
	@echo "Cleanup complete!"

# Push to registry
push:
	@echo "Pushing image to registry..."
	docker tag $(IMAGE_NAME):$(IMAGE_TAG) $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)
	docker push $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)

# Security scan with trivy (if installed)
scan:
	@echo "Scanning image for vulnerabilities..."
	@which trivy > /dev/null || (echo "Trivy not installed. Install with: brew install trivy" && exit 1)
	trivy image $(IMAGE_NAME):$(IMAGE_TAG)

# Check image size
size:
	@echo "Image size:"
	@docker images $(IMAGE_NAME):$(IMAGE_TAG) --format "{{.Repository}}:{{.Tag}} - {{.Size}}"

# Prune Docker system
prune:
	@echo "Pruning Docker system..."
	docker system prune -af

# Restart containers
restart: stop run
