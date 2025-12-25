#!/bin/bash
set -e

cd "$(dirname "${BASH_SOURCE[0]}")"

echo "Localization Editor - Deployment"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "▶ Running database migration..."
cd Server
./venv/bin/python3 migrate_localization_schema.py
echo "✓ Migration complete"

echo ""
echo "▶ Building frontend..."
cd ../Client/Browser
npm install --legacy-peer-deps > /dev/null 2>&1
npm run build > /dev/null 2>&1
echo "✓ Frontend built"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Deployment complete!"
