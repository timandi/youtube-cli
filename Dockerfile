# Multi-stage build for YouTube Remote MCP Server
# Stage 1: Builder - Install dependencies
FROM python:3.13-slim AS builder

# Set working directory
WORKDIR /build

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .

# Create virtual environment and install dependencies
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Upgrade pip and install dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Stage 2: Runtime - Minimal production image
FROM python:3.13-slim

# Add metadata
LABEL maintainer="YouTube Remote"
LABEL description="MCP server for controlling YouTube playback on TV"
LABEL version="1.0"

# Create non-root user for security
RUN groupadd -r ytremote && \
    useradd -r -g ytremote -u 1000 -m -s /bin/bash ytremote

# Set working directory
WORKDIR /app

# Copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv

# Copy application code
COPY --chown=ytremote:ytremote youtube-remote/ ./youtube-remote/

# Set up configuration directory with proper permissions
RUN mkdir -p /home/ytremote/.config/youtube-remote && \
    chown -R ytremote:ytremote /home/ytremote/.config

# Set environment variables
ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    HOME=/home/ytremote

# Switch to non-root user
USER ytremote

# Volume for persistent configuration
VOLUME ["/home/ytremote/.config/youtube-remote"]

# Set working directory to where the code is
WORKDIR /app/youtube-remote

# Health check (basic Python import test)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import sys; from remote import YouTubeRemote; sys.exit(0)"

# Default command - run the MCP server
CMD ["python", "server.py"]
