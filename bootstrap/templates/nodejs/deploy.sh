#!/bin/bash

# Deploy script for Node.js Application

set -e

echo "🚀 Starting deployment..."

# 1. Install dependencies
echo "📦 Installing dependencies..."
if [ -f "yarn.lock" ]; then
    yarn install --frozen-lockfile
else
    npm ci
fi

# 2. Build application (if needed)
if grep -q "\"build\":" package.json; then
    echo "🔨 Building application..."
    if [ -f "yarn.lock" ]; then
        yarn build
    else
        npm run build
    fi
fi

# 3. Build Docker image
echo "🐳 Building Docker image..."
docker-compose build

# 4. Start services
echo "▶️ Starting services..."
docker-compose up -d

# 5. Health check
echo "🏥 Waiting for health check..."
# Simple wait loop
for i in {1..30}; do
    if curl -s -f http://localhost:3000/health >/dev/null; then
        echo "✅ Application is healthy!"
        exit 0
    fi
    echo -n "."
    sleep 2
done

echo "❌ Health check failed!"
docker-compose logs --tail=50 app
exit 1
