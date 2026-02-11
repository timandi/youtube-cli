# YouTube Remote - Docker Quick Start

## 🚀 Quick Commands

### Build & Run (Easiest)

```bash
# Using Makefile (recommended)
make build          # Build the Docker image
make run            # Start the container
make logs           # View logs
make stop           # Stop the container
make clean          # Clean up everything

# Or using Docker Compose directly
docker-compose up -d              # Start in background
docker-compose logs -f            # Follow logs
docker-compose down               # Stop and remove
```

### First Time Setup

```bash
# 1. Build the image
make build

# 2. Start the container
make run

# 3. Pair with your TV
# - Open YouTube on TV → Settings → Link with TV code
# - Note the pairing code
# - Use MCP tool: pair_tv("YOUR-CODE-HERE")
```

### Integration with Claude Desktop

Add to `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "youtube-remote": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "-v", "youtube-config:/home/ytremote/.config/youtube-remote",
        "youtube-remote:latest"
      ]
    }
  }
}
```

## 🔧 Common Operations

### Development Mode

```bash
# Run with source code mounted (auto-reload)
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up
```

### View Logs

```bash
make logs                           # Using Makefile
docker-compose logs -f              # Using Docker Compose
docker logs -f youtube-remote-mcp   # Using Docker directly
```

### Shell Access

```bash
make shell                          # Using Makefile
docker exec -it youtube-remote-mcp /bin/bash
```

### Reset Configuration

```bash
# Remove pairing config and start fresh
docker volume rm youtube-config
make run
```

## 📦 Kubernetes Deployment

```bash
# Deploy
kubectl apply -k k8s/

# Check status
kubectl get pods -l app=youtube-remote

# View logs
kubectl logs -f deployment/youtube-remote-mcp

# Delete
kubectl delete -k k8s/
```

## 🐛 Troubleshooting

### Container won't start
```bash
make logs                # Check logs
docker images            # Verify image exists
```

### Need to rebuild from scratch
```bash
make clean              # Clean everything
make build-no-cache     # Build without cache
make run
```

### Check image size
```bash
make size
```

### Security scan
```bash
make scan              # Requires trivy installed
```

## 📚 Documentation

- Full Docker guide: `DOCKER.md`
- Kubernetes guide: `k8s/README.md`
- Complete summary: `CONTAINERIZATION_SUMMARY.md`
- All commands: `make help`

## ✅ Verify Installation

```bash
# Test the build
make test

# Or manually
docker run --rm youtube-remote:latest python -c "from remote import YouTubeRemote; print('OK')"
```

---

**Image**: `youtube-remote:latest` (326MB)
**User**: `ytremote` (UID 1000)
**Config**: Persisted in `youtube-config` Docker volume
