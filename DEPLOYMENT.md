# Hetzner Server Deployment Guide

## Server Details
- **Host:** 95.216.221.175
- **User:** root
- **SSH Key:** `~/.ssh/id_ed25519`
- **Project Location:** `/opt/NiceTradersApp`
- **Admin UI Location:** `/var/www/nicetraders-admin`

## Database Details
- **Host:** localhost
- **User:** stevenelson
- **Password:** mwitcitw711
- **Database:** nicetraders

## Deployment Steps

### 1. Prepare Local Changes
Make sure all changes are committed locally:
```bash
cd /Users/stevenelson/Documents/GitHub/NiceTradersApp
git add -A
git commit -m "your commit message"
```

### 2. Push to GitHub
```bash
git push
```

### 3. Connect to Hetzner
```bash
ssh -i ~/.ssh/id_ed25519 root@95.216.221.175
```

### 4. Update Server Code
```bash
cd /opt/NiceTradersApp
git pull
```

### 5. Deploy Database Schema (if schema changed)

#### Prerequisites
Ensure these files exist in `/opt/NiceTradersApp/Server`:
- `database_schema_ordered.sql` - Schema with tables in proper FK dependency order
- `database_schema_safe.sql` - Schema with `CREATE TABLE IF NOT EXISTS` syntax
- `update_database_schema.sh` - Update script with FK checks disabled

#### If you need to regenerate these files:
```bash
cd /opt/NiceTradersApp/Server

# Regenerate the safe schema (if database_schema_ordered.sql was updated)
sed 's/CREATE TABLE `/CREATE TABLE IF NOT EXISTS `/g' database_schema_ordered.sql > database_schema_safe.sql
```

#### Run the update script:
```bash
cd /opt/NiceTradersApp/Server
./update_database_schema.sh
```

This will:
1. Create a backup of the current database at `backups/nicetraders_YYYYMMDD_HHMMSS.sql`
2. Disable foreign key checks
3. Apply all schema changes (creates new tables, ignores existing ones)
4. Re-enable foreign key checks

### 6. Restart Services (if needed)
If backend changes were made:
```bash
cd /opt/NiceTradersApp/Server
./run.sh
```

If admin UI changes were made:
```bash
cd /var/www/nicetraders-admin
npm install
npm run build
# Restart web server as needed
```

## Troubleshooting

### Database Backup Failed
- Error: `mysqldump: Error: 'Access denied; you need (at least one of) the PROCESS privilege(s)'`
- This is a warning, not a failure. The backup still completes.

### Foreign Key Constraint Error
- If `ERROR 1215 (HY000)` occurs, ensure:
  1. `database_schema_ordered.sql` has tables in correct dependency order (users before tables that reference users)
  2. `database_schema_safe.sql` was regenerated with `IF NOT EXISTS`
  3. The update script disables FK checks during import

### Connection Issues
Verify credentials work locally:
```bash
cd /Users/stevenelson/Documents/GitHub/NiceTradersApp/Server && venv/bin/python3 << 'EOF'
import pymysql
db = pymysql.connect(host='localhost', user='stevenelson', password='mwitcitw711', database='nicetraders')
cursor = db.cursor()
cursor.execute('SELECT COUNT(*) FROM users')
print(cursor.fetchone())
db.close()
EOF
```

## Files Reference

- `Server/database_schema.sql` - Current schema exported from local database
- `Server/database_schema_ordered.sql` - Schema reordered by FK dependencies
- `Server/database_schema_safe.sql` - Safe version with `IF NOT EXISTS` (generated on-demand)
- `Server/update_database_schema.sh` - Main deployment script
- `Server/export_schema.py` - Export current local schema to SQL file
- `Server/reorder_schema.py` - Reorder schema by FK dependencies using topological sort
