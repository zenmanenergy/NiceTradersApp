#!/bin/bash

echo "🚀 Starting deployment..."

# Navigate to project root
cd /opt/NiceTradersApp

# Pull latest code
echo "📥 Pulling latest code from Git..."
git pull

# Deploy Flask API
echo "🔄 Restarting Flask service..."
sudo systemctl restart nicetraders

# Deploy Svelte Admin
echo "🎨 Building Svelte app..."
cd Client/Browser
npm install
npm run build

echo "📦 Deploying Svelte build..."
sudo rm -rf /var/www/nicetraders-admin/*
sudo cp -r build/* /var/www/nicetraders-admin/

echo "✅ Deployment complete!"
echo "API: https://api.nicetraders.net"
echo "Admin: https://admin.nicetraders.net"