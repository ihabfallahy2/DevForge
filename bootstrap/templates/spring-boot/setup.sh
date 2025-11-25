#!/bin/bash

# Setup script for Spring Boot Application

set -e

echo "🔧 Setting up project..."

# Make scripts executable
chmod +x deploy.sh
if [ -f "mvnw" ]; then
    chmod +x mvnw
fi
if [ -f "gradlew" ]; then
    chmod +x gradlew
fi

# Create necessary directories
mkdir -p logs

echo "✅ Setup complete!"
