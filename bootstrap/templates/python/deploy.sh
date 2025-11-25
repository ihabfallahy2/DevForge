#!/bin/bash

# Deploy script for Python Application

set -e

echo "🚀 Starting deployment..."

# 1. Install dependencies (optional, for local checks)
echo "📦 Installing dependencies..."
if [ -f "requirements.txt" ]; then
    pip install -r requirements.txt
elif [ -f "pyproject.toml" ]; then
    pip install .
fi

# 2. Build Docker image
echo "🐳 Building Docker image..."
docker-compose build

# 3. Start services
echo "▶️ Starting services..."
docker-compose up -d

# 4. Health check
echo "🏥 Waiting for health check..."
# Simple wait loop
for i in {1..30}; do
    if curl -s -f http://localhost:8000/health >/dev/null; then
        echo "✅ Application is healthy!"
        exit 0
    fi
    echo -n "."
    sleep 2
done

echo "❌ Health check failed!"
docker-compose logs --tail=50 app
exit 1
