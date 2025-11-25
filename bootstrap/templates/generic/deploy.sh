#!/bin/bash

# Deploy script for Generic Application

set -e

echo "🚀 Starting deployment..."

# 1. Start services
echo "▶️ Starting services..."
if [ -f "docker-compose.yml" ]; then
    docker-compose up -d
else
    echo "⚠️ No docker-compose.yml found, skipping service start"
fi

echo "✅ Deployment complete!"
