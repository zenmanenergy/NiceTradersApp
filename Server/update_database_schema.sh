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

echo "🔄 Applying schema updates..."
mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME << EOF
SET FOREIGN_KEY_CHECKS=0;
SET UNIQUE_CHECKS=0;
EOF

mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME < database_schema_safe.sql

mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME << EOF
SET FOREIGN_KEY_CHECKS=1;
SET UNIQUE_CHECKS=1;
EOF

if [ $? -eq 0 ]; then
    echo "✅ Database schema updated successfully!"
    echo "💾 Backup saved at: $BACKUP_FILE"
else
    echo "❌ Schema update failed!"
    echo "💡 Your database has been backed up at: $BACKUP_FILE"
    exit 1
fi

echo -e "${YELLOW}Database Configuration:${NC}"
echo "  Host: $DB_HOST"
echo "  User: $DB_USER"
echo "  Database: $DB_NAME"
echo ""

# Test database connection
echo -e "${YELLOW}Testing database connection...${NC}"
if mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -e "SELECT 1;" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Database connection successful${NC}"
else
    echo -e "${RED}✗ Failed to connect to database${NC}"
    echo "Please verify your credentials:"
    echo "  DB_HOST=$DB_HOST"
    echo "  DB_USER=$DB_USER"
    echo "  DB_NAME=$DB_NAME"
    exit 1
fi

echo ""

# List of migration files to run in order
declare -a MIGRATIONS=(
    "000_create_base_schema.sql"
    "001_add_user_devices_table.sql"
    "002_add_language_support.sql"
    "003_add_loginview_translations.sql"
    "004_add_negotiation_tables.sql"
    "004_password_reset_tokens.sql"
    "007_add_rounding_preference.sql"
    "008_add_geocoding_cache.sql"
    "create_translations_table.sql"
)

# Run migrations
echo -e "${YELLOW}Running migrations...${NC}"
echo ""

success_count=0
fail_count=0
failed_migrations=()

for migration in "${MIGRATIONS[@]}"; do
    migration_file="$MIGRATIONS_DIR/$migration"
    
    if [ ! -f "$migration_file" ]; then
        echo -e "${YELLOW}⊘ SKIPPED${NC}: $migration (file not found)"
        continue
    fi
    
    echo -n "Running $migration... "
    
    if mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < "$migration_file" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ SUCCESS${NC}"
        ((success_count++))
    else
        echo -e "${RED}✗ FAILED${NC}"
        ((fail_count++))
        failed_migrations+=("$migration")
    fi
done

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Migration Summary${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Successful: $success_count${NC}"
if [ $fail_count -gt 0 ]; then
    echo -e "${RED}✗ Failed: $fail_count${NC}"
    echo ""
    echo -e "${RED}Failed migrations:${NC}"
    for failed in "${failed_migrations[@]}"; do
        echo "  - $failed"
    done
fi

echo ""

# Verify tables exist
echo -e "${YELLOW}Verifying database tables...${NC}"
table_count=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" -sN -e "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='$DB_NAME';")
echo -e "${GREEN}Total tables in database: $table_count${NC}"

echo ""

if [ $fail_count -eq 0 ]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ All migrations completed successfully!${NC}"
    echo -e "${GREEN}========================================${NC}"
    exit 0
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}✗ Some migrations failed${NC}"
    echo -e "${RED}========================================${NC}"
    exit 1
fi
