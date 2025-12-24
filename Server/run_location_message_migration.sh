#!/bin/bash

# Run location proposal message migration
# This script applies the migration to add message column to listing_meeting_location table

cd "$(dirname "$0")"

echo "🔄 Running migration: Add message column to location proposals..."

venv/bin/python3 << 'EOF'
import pymysql

try:
    db = pymysql.connect(
        host='localhost',
        user='stevenelson',
        password='mwitcitw711',
        database='nicetraders'
    )
    cursor = db.cursor()
    
    # Check if column already exists
    cursor.execute("SHOW COLUMNS FROM listing_meeting_location LIKE 'message'")
    result = cursor.fetchone()
    
    if result:
        print("✓ Message column already exists")
    else:
        print("Adding message column...")
        cursor.execute("""
            ALTER TABLE listing_meeting_location 
            ADD COLUMN message TEXT DEFAULT NULL AFTER meeting_location_name
        """)
        db.commit()
        print("✓ Message column added successfully")
    
    cursor.close()
    db.close()
    
except Exception as e:
    print(f"✗ Error: {e}")
    exit(1)
EOF

echo "✓ Migration complete!"
