# Database Schema Update Script

## Overview
The `update_database_schema.sh` script automatically applies all database migrations to your MySQL database on Ubuntu servers.

## Usage

### Basic Usage (with default credentials)
```bash
./update_database_schema.sh
```
This will use the default credentials from the script configuration.

### Custom Database Configuration
You can override the default settings by setting environment variables:

```bash
# Using custom host, user, password, and database name
DB_HOST=your.database.host \
DB_USER=your_username \
DB_PASSWORD=your_password \
DB_NAME=nicetraders \
./update_database_schema.sh
```

### Example: Ubuntu Server
```bash
# SSH into your Ubuntu server
ssh user@ubuntu-server

# Navigate to the Server directory
cd /path/to/NiceTradersApp/Server

# Run with custom database credentials
DB_HOST=localhost \
DB_USER=ubuntu_db_user \
DB_PASSWORD=ubuntu_db_password \
DB_NAME=nicetraders \
./update_database_schema.sh
```

## What the Script Does

1. **Validates Configuration**: Checks database host, user, and database name
2. **Tests Connection**: Verifies MySQL connection before running migrations
3. **Runs Migrations**: Executes all migration files in the correct order:
   - 000_create_base_schema.sql (creates all core tables)
   - 001_add_user_devices_table.sql
   - 002_add_language_support.sql
   - 003_add_loginview_translations.sql
   - 004_add_negotiation_tables.sql
   - 004_password_reset_tokens.sql
   - 007_add_rounding_preference.sql
   - 008_add_geocoding_cache.sql
   - create_translations_table.sql
4. **Reports Status**: Shows success/failure of each migration
5. **Verifies Result**: Confirms all tables were created

## Default Configuration

The script uses these default values (found at the top of the script):
```bash
DB_HOST=${DB_HOST:-localhost}
DB_USER=${DB_USER:-stevenelson}
DB_PASSWORD=${DB_PASSWORD:-mwitcitw711}
DB_NAME=${DB_NAME:-nicetraders}
```

## Output Example

```
========================================
NiceTradersApp Database Schema Update
========================================

Database Configuration:
  Host: localhost
  User: stevenelson
  Database: nicetraders

Testing database connection...
✓ Database connection successful

Running migrations...

Running 000_create_base_schema.sql... ✓ SUCCESS
Running 001_add_user_devices_table.sql... ✓ SUCCESS
Running 002_add_language_support.sql... ✓ SUCCESS
...

========================================
Migration Summary
========================================
✓ Successful: 9
✗ Failed: 0

Total tables in database: 27

========================================
✓ All migrations completed successfully!
========================================
```

## Requirements

- MySQL client installed on Ubuntu (`mysql-client` package)
- Access to MySQL server with valid credentials
- All migration files present in the `migrations/` directory
- Sufficient privileges to create tables and indexes

## Installation

If `mysql-client` is not installed on your Ubuntu server:
```bash
sudo apt-get update
sudo apt-get install mysql-client
```

## Troubleshooting

### Connection Failed
```
✗ Failed to connect to database
```
- Verify the MySQL server is running
- Check hostname, username, and password
- Ensure the database exists

### Migration Failures
If a specific migration fails:
1. Run the migration file manually to see detailed error:
   ```bash
   mysql -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME < migrations/filename.sql
   ```
2. Check for foreign key constraints
3. Verify table dependencies

### Permission Denied
```
-bash: ./update_database_schema.sh: Permission denied
```
Make the script executable:
```bash
chmod +x update_database_schema.sh
```

## Safety Notes

- **Backup First**: Always backup your database before running schema updates
  ```bash
  mysqldump -h $DB_HOST -u $DB_USER -p$DB_PASSWORD $DB_NAME > backup.sql
  ```
- **Test First**: Run on a development database before production
- **Review Changes**: Check the migration files to understand what changes will be applied

## Idempotency

All migrations use `CREATE TABLE IF NOT EXISTS` and conditional `ALTER TABLE` statements, making them safe to run multiple times. Running the script again will skip already-created tables.
