#!/bin/bash

# Setup script for Python Application

set -e

echo "🔧 Setting up project..."

# Make scripts executable
chmod +x deploy.sh

# Create virtual environment if not exists
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Create necessary directories
mkdir -p logs

echo "✅ Setup complete!"
