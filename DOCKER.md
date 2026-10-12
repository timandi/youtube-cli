# Docker Deployment Guide

This guide covers how to build, run, and deploy the YouTube Remote MCP server using Docker.

## Quick Start

### Build the Docker Image

```bash
docker build -t youtube-remote:latest .
```

### Run with Docker Compose (Recommended)

```bash
# Start the service
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the service
docker-compose down
```

### Run with Docker

```bash
# Run in interactive mode
docker run -it --rm \
  -v youtube-config:/home/ytremote/.config/youtube-remote \
  youtube-remote:latest

# Run in background
docker run -d \
  --name youtube-remote \
  -v youtube-config:/home/ytremote/.config/youtube-remote \
  youtube-remote:latest
```

## Initial Pairing

When running for the first time, you'll need to pair with your YouTube TV:

1. Open YouTube on your TV
2. Navigate to Settings → Link with TV code
3. Note the pairing code displayed on screen
4. Use the MCP tool `pair_tv` with the pairing code

The pairing configuration will be saved in the Docker volume and persist across container restarts.

## Configuration

### Environment Variables

Copy `.env.example` to `.env` and customize:

```bash
cp .env.example .env
```

Available environment variables:

- `PYTHONUNBUFFERED=1` - Enable real-time Python output
- `LOG_LEVEL` - Set logging level (DEBUG, INFO, WARNING, ERROR)

### Volumes

The container uses a named volume to persist configuration:

- `youtube-config` - Stores YouTube TV pairing data at `/home/ytremote/.config/youtube-remote`

## Usage with MCP Clients

### Claude Desktop Integration

Add to your Claude Desktop MCP configuration (`~/Library/Application Support/Claude/claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "youtube-remote": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "-v",
        "youtube-config:/home/ytremote/.config/youtube-remote",
        "youtube-remote:latest"
      ]
    }
  }
}
```

## Development

### Mount Source Code for Development

Uncomment the development volume in `docker-compose.yml`:

```yaml
volumes:
  - youtube-config:/home/ytremote/.config/youtube-remote
  - ./youtube-remote:/app/youtube-remote:ro  # Uncomment this line
```

### Build with Custom Python Version

Edit the Dockerfile and change the base image:

```dockerfile
FROM python:3.12-slim AS builder
```

## Production Deployment

### Build Optimized Image

```bash
docker build \
  --target runtime \
  --tag youtube-remote:prod \
  --compress \
  .
```

### Security Hardening

The Dockerfile includes several security features:

- ✅ Multi-stage build to minimize image size
- ✅ Non-root user (`ytremote` with UID 1000)
- ✅ No new privileges security option
- ✅ Minimal Python slim base image
- ✅ Health checks for container monitoring
- ✅ No cache for pip to reduce attack surface

### Resource Limits

Adjust CPU and memory limits in `docker-compose.yml`:

```yaml
deploy:
  resources:
    limits:
      cpus: '1.0'
      memory: 1G
```

## Troubleshooting

### Container won't start

Check logs:

```bash
docker-compose logs youtube-remote
```

### Pairing issues

1. Ensure the config volume has proper permissions
2. Remove old config and re-pair:

```bash
docker volume rm youtube-config
docker-compose up -d
```

### Health check failing

Test manually:

```bash
docker exec youtube-remote python -c "from remote import YouTubeRemote; print('OK')"
```

## Maintenance

### Update Dependencies

1. Update `requirements.txt`
2. Rebuild the image:

```bash
docker-compose build --no-cache
```

### Clean Up

Remove all containers, images, and volumes:

```bash
docker-compose down -v
docker rmi youtube-remote:latest
```

## Advanced Usage

### Using with Kubernetes

See `k8s/` directory for Kubernetes deployment manifests.

### Custom Logging

Mount a custom logging configuration:

```bash
docker run -it \
  -v $(pwd)/logging.conf:/app/logging.conf \
  -v youtube-config:/home/ytremote/.config/youtube-remote \
  youtube-remote:latest
```

### Debugging

Run with shell access:

```bash
docker run -it --rm \
  -v youtube-config:/home/ytremote/.config/youtube-remote \
  --entrypoint /bin/bash \
  youtube-remote:latest
```
