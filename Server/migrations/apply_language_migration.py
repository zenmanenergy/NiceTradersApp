#!/usr/bin/env python3
"""
Migration script to add preferred_language column to users table
Run this script once to update the database schema
"""

import sys
import os

# Add parent directory to path to import Database
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from _Lib import Database

def apply_migration():
    cursor, connection = Database.ConnectToDatabase()
    
    try:
        # Check if column already exists
        cursor.execute("""
            SELECT COUNT(*) as count
            FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
            AND TABLE_NAME = 'users'
            AND COLUMN_NAME = 'PreferredLanguage'
        """)
        
        result = cursor.fetchone()
        
        if result['count'] > 0:
            print("✓ PreferredLanguage column already exists. No migration needed.")
            connection.close()
            return
        
        print("Adding PreferredLanguage column to users table...")
        
        # Add the column
        cursor.execute("""
            ALTER TABLE users 
            ADD COLUMN PreferredLanguage VARCHAR(10) DEFAULT 'en' AFTER Bio
        """)
        
        # Add index
        cursor.execute("""
            CREATE INDEX idx_preferred_language ON users(PreferredLanguage)
        """)
        
        connection.commit()
        
        print("✓ Migration completed successfully!")
        print("✓ PreferredLanguage column added to users table")
        print("✓ Index created on PreferredLanguage")
        
    except Exception as e:
        connection.rollback()
        print(f"✗ Migration failed: {str(e)}")
        raise
    finally:
        connection.close()

if __name__ == "__main__":
    print("=" * 50)
    print("Language Preference Migration")
    print("=" * 50)
    apply_migration()
