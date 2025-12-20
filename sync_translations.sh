#!/bin/bash

echo "🔄 Syncing translations to production database..."

# Get all translations from local database and sync to production
cd /opt/NiceTradersApp

python3 << 'EOF'
import pymysql
import sys

try:
    # Connect to database
    db = pymysql.connect(
        host='localhost',
        user='stevenelson',
        password='mwitcitw711',
        database='nicetraders'
    )
    cursor = db.cursor()
    
    # Get all translations
    cursor.execute("SELECT translation_key, language_code, translation_value, updated_at FROM translations ORDER BY translation_key, language_code")
    results = cursor.fetchall()
    
    print(f"Found {len(results)} translations to sync...")
    
    # Insert/update all translations
    count = 0
    for row in results:
        key, lang, value, updated_at = row
        try:
            sql = """
                INSERT INTO translations (translation_key, language_code, translation_value, updated_at)
                VALUES (%s, %s, %s, %s)
                ON DUPLICATE KEY UPDATE
                translation_value = VALUES(translation_value),
                updated_at = VALUES(updated_at)
            """
            cursor.execute(sql, (key, lang, value, updated_at))
            count += 1
            if count % 500 == 0:
                print(f"  Synced {count} translations...")
        except Exception as e:
            print(f"Error syncing {key} ({lang}): {e}")
            continue
    
    # Commit all changes
    db.commit()
    print(f"✓ Successfully synced {count} translations!")
    
    cursor.close()
    db.close()
    
except Exception as e:
    print(f"✗ Error: {e}")
    sys.exit(1)
EOF

if [ $? -eq 0 ]; then
    echo "✓ Translation sync complete!"
    echo "Restarting Flask service..."
    sudo systemctl restart nicetraders
    echo "✓ Service restarted!"
else
    echo "✗ Translation sync failed!"
    exit 1
fi
