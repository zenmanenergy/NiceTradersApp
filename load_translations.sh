#!/bin/bash

# Load translations from translations.json into the nicetraders database
# This script reads the translations.json file and inserts all records into the translations table

cd /Users/stevenelson/Documents/GitHub/NiceTradersApp/Server

# Run Python script to load translations
./venv/bin/python3 << 'EOFPYTHON'
import pymysql
import json
import sys

# Read translations.json
try:
    with open('./translations.json', 'r', encoding='utf-8') as f:
        translations = json.load(f)
    print(f"Loaded {len(translations)} translation entries from translations.json")
except Exception as e:
    print(f"Error reading translations.json: {e}")
    sys.exit(1)

# Connect to database
try:
    db = pymysql.connect(
        host='localhost',
        user='stevenelson',
        password='mwitcitw711',
        database='nicetraders'
    )
    cursor = db.cursor()
    print("Connected to nicetraders database")
except Exception as e:
    print(f"Error connecting to database: {e}")
    sys.exit(1)

# Insert translations
inserted = 0
updated = 0
errors = 0

for entry in translations:
    try:
        sql = """
            INSERT INTO translations (translation_key, language_code, translation_value, updated_at, created_at)
            VALUES (%s, %s, %s, %s, %s)
            ON DUPLICATE KEY UPDATE
                translation_value = VALUES(translation_value),
                updated_at = VALUES(updated_at)
        """
        cursor.execute(sql, (
            entry['translation_key'],
            entry['language_code'],
            entry['translation_value'],
            entry['updated_at'],
            entry['created_at']
        ))
        
        # Track if this was an insert or update
        if cursor.rowcount == 1:
            inserted += 1
        elif cursor.rowcount == 2:
            updated += 1
            
    except Exception as e:
        errors += 1
        print(f"Error inserting translation {entry.get('translation_key', 'UNKNOWN')}: {e}")

# Commit and close
try:
    db.commit()
    print(f"\nSuccess!")
    print(f"  Inserted: {inserted} new entries")
    print(f"  Updated: {updated} existing entries")
    if errors > 0:
        print(f"  Errors: {errors}")
except Exception as e:
    print(f"Error committing transaction: {e}")
    sys.exit(1)
finally:
    cursor.close()
    db.close()

EOFPYTHON
