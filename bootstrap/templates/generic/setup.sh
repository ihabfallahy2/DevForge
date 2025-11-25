#!/bin/bash

# Setup script for Generic Application

set -e

echo "🔧 Setting up project..."

# Make scripts executable
if [ -f "deploy.sh" ]; then
    chmod +x deploy.sh
fi

echo "✅ Setup complete!"
