#!/bin/bash
# Import translations on production server (replaces entire table)

set -e

if [ ! -f "$1" ]; then
    echo "Usage: $0 <sql_file>"
    echo "Example: $0 translations_sync.sql"
    exit 1
fi

SQL_FILE="$1"

echo "Importing translations..."
mysql -h localhost -u stevenelson -pmwitcitw711 nicetraders < "$SQL_FILE"

COUNT=$(mysql -h localhost -u stevenelson -pmwitcitw711 nicetraders \
  -e "SELECT COUNT(*) FROM translations" | tail -1)

echo "✓ Complete ($COUNT translations)"
