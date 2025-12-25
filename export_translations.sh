#!/bin/bash
# Export local translations table for syncing to production

cd /Users/stevenelson/Documents/GitHub/NiceTradersApp/Server

echo "Exporting translations table..."

venv/bin/python3 << 'EOF'
import pymysql
import json

db = pymysql.connect(
    host='localhost',
    user='stevenelson',
    password='mwitcitw711',
    database='nicetraders'
)
cursor = db.cursor()

# Get all translations
cursor.execute("SELECT translation_key, language_code, translation_value FROM translations ORDER BY translation_key, language_code")
rows = cursor.fetchall()

# Generate SQL INSERT statements
sql_lines = []
for row in rows:
    key, lang, value = row
    # Escape single quotes
    value_escaped = value.replace("'", "''")
    sql_lines.append(f"REPLACE INTO translations (translation_key, language_code, translation_value) VALUES ('{key}', '{lang}', '{value_escaped}');")

# Write to file
with open('../translations_sync.sql', 'w') as f:
    f.write('\n'.join(sql_lines))

print(f"✓ Exported {len(rows)} translation records")
print(f"  File: translations_sync.sql")

db.close()
EOF

echo ""
echo "To sync to production server:"
echo "  1. Copy file: scp translations_sync.sql your_server:/tmp/"
echo "  2. Run on server: bash sync_translations_to_server.sh /tmp/translations_sync.sql"
