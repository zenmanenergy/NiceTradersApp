#!/bin/bash

echo "🗄️ Starting database schema update..."

# Navigate to project directory
cd /opt/NiceTradersApp/Server

# Get database credentials from environment or use defaults
DB_HOST=${DB_HOST:-localhost}
DB_USER=${DB_USER:-stevenelson}
DB_PASSWORD=${DB_PASSWORD:-mwitcitw711}
DB_NAME=${DB_NAME:-nicetraders}

# Backup current database
BACKUP_FILE="/opt/NiceTradersApp/Server/backups/nicetraders_$(date +%Y%m%d_%H%M%S).sql"
mkdir -p /opt/NiceTradersApp/Server/backups

echo "📦 Creating database backup at $BACKUP_FILE..."
mysqldump -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME > "$BACKUP_FILE"

if [ $? -ne 0 ]; then
    echo "❌ Backup failed!"
    exit 1
fi

echo "✅ Backup created successfully"

# Update schema
echo "🔄 Applying new schema..."
mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME < database_schema.sql

if [ $? -eq 0 ]; then
    echo "✅ Database schema updated successfully!"
    echo "💾 Backup saved at: $BACKUP_FILE"
else
    echo "❌ Schema update failed!"
    echo "💡 Your database has been backed up at: $BACKUP_FILE"
    exit 1
fi
