#!/bin/bash
# Import translations on production server (replaces entire table)

set -e

if [ ! -f "$1" ]; then
    echo "Usage: $0 <sql_file>"
    echo "Example: $0 translations_sync.sql"
    exit 1
fi

SQL_FILE="$1"

echo "════════════════════════════════════════"
echo "Syncing Translations Table"
echo "════════════════════════════════════════"
echo ""

echo "▶ Backing up current translations..."
BACKUP_FILE="translations_backup_$(date +%Y%m%d_%H%M%S).sql"
mysqldump -h localhost -u stevenelson -pmwitcitw711 nicetraders translations \
  > "$BACKUP_FILE"
echo "✓ Backup saved: $BACKUP_FILE"

echo ""
echo "▶ Importing new translations..."
mysql -h localhost -u stevenelson -pmwitcitw711 nicetraders < "$SQL_FILE"

echo ""
echo "▶ Verifying..."
COUNT=$(mysql -h localhost -u stevenelson -pmwitcitw711 nicetraders \
  -e "SELECT COUNT(*) FROM translations" | tail -1)

echo "✓ Import complete"
echo ""
echo "════════════════════════════════════════"
echo "✓ Sync complete! ($COUNT translations)"
echo "════════════════════════════════════════"
echo ""
echo "Backup saved: $BACKUP_FILE"
echo "If needed, rollback with:"
echo "  mysql -u stevenelson -pmwitcitw711 nicetraders < $BACKUP_FILE"
