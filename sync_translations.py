#!/usr/bin/env python3
"""
Sync translations from local database to production database
Run this on the production server: python3 sync_translations.py
"""

import pymysql
import sys

def sync_translations():
    try:
        # Connect to local database
        print("Connecting to nicetraders database...")
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
                # Use INSERT ... ON DUPLICATE KEY UPDATE for upsert
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
                print(f"Error inserting {key} ({lang}): {e}")
                continue
        
        # Commit all changes
        db.commit()
        print(f"✓ Successfully synced {count} translations!")
        
        cursor.close()
        db.close()
        
        return True
        
    except Exception as e:
        print(f"✗ Error: {e}")
        return False

if __name__ == '__main__':
    success = sync_translations()
    sys.exit(0 if success else 1)
