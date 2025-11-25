#!/bin/bash

# Deploy script for Spring Boot Application

set -e

echo "🚀 Starting deployment..."

# 1. Build application
echo "📦 Building application..."
if [ -f "mvnw" ]; then
    ./mvnw clean package -DskipTests
elif [ -f "gradlew" ]; then
    ./gradlew build -x test
else
    echo "❌ No build script found (mvnw/gradlew)"
    exit 1
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
    if curl -s -f http://localhost:8080/actuator/health >/dev/null; then
        echo "✅ Application is healthy!"
        exit 0
    fi
    echo -n "."
    sleep 2
done

echo "❌ Health check failed!"
docker-compose logs --tail=50 app
exit 1
