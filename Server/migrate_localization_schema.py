#!/usr/bin/env python3
"""
Database schema migrations for localization editor
Adds history tracking and additional columns to translations table
"""

import pymysql
from datetime import datetime

DB_HOST = 'localhost'
DB_USER = 'stevenelson'
DB_PASSWORD = 'mwitcitw711'
DB_NAME = 'nicetraders'

def run_migrations():
    """Run all database migrations"""
    db = pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME
    )
    cursor = db.cursor()
    
    print("=" * 70)
    print("Database Schema Migration for Localization Editor")
    print("=" * 70)
    
    try:
        # 1. Check if translations table exists
        print("\n1. Checking translations table structure...")
        cursor.execute("DESCRIBE translations")
        columns = [row[0] for row in cursor.fetchall()]
        print(f"   Current columns: {', '.join(columns)}")
        
        # 2. Add new columns if they don't exist
        print("\n2. Adding new columns to translations table...")
        
        if 'updated_by' not in columns:
            print("   - Adding updated_by column...")
            cursor.execute("""
                ALTER TABLE translations 
                ADD COLUMN updated_by INT NULL DEFAULT NULL 
                COMMENT 'Admin user ID who last updated this translation'
            """)
            db.commit()
            print("     ✓ Added updated_by")
        
        if 'status' not in columns:
            print("   - Adding status column...")
            cursor.execute("""
                ALTER TABLE translations 
                ADD COLUMN status VARCHAR(50) DEFAULT 'active' 
                COMMENT 'Status: active, review_needed, deprecated'
            """)
            db.commit()
            print("     ✓ Added status")
        
        if 'notes' not in columns:
            print("   - Adding notes column...")
            cursor.execute("""
                ALTER TABLE translations 
                ADD COLUMN notes TEXT NULL 
                COMMENT 'Optional notes about this translation'
            """)
            db.commit()
            print("     ✓ Added notes")
        
        # 3. Create translation history table
        print("\n3. Creating translation_history table...")
        
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS translation_history (
                id INT AUTO_INCREMENT PRIMARY KEY,
                translation_key VARCHAR(255) NOT NULL,
                language_code VARCHAR(10) NOT NULL,
                old_value LONGTEXT,
                new_value LONGTEXT,
                changed_by INT NULL COMMENT 'Admin user ID',
                changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                change_reason VARCHAR(255) COMMENT 'e.g., English updated, Manual edit',
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_key (translation_key),
                INDEX idx_language (language_code),
                INDEX idx_changed_at (changed_at)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        """)
        db.commit()
        print("   ✓ Created translation_history table")
        
        # 4. Create view inventory cache table
        print("\n4. Creating view_translation_keys_cache table...")
        
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS view_translation_keys_cache (
                id INT AUTO_INCREMENT PRIMARY KEY,
                view_id VARCHAR(255) NOT NULL UNIQUE,
                view_type VARCHAR(50) NOT NULL COMMENT 'iOS or Web',
                view_path VARCHAR(500) NOT NULL,
                translation_keys JSON COMMENT 'Array of translation key strings',
                last_scanned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                key_count INT DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                INDEX idx_view_type (view_type),
                INDEX idx_last_scanned (last_scanned_at)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        """)
        db.commit()
        print("   ✓ Created view_translation_keys_cache table")
        
        # 5. Populate view_translation_keys_cache from inventory
        print("\n5. Populating view cache from inventory...")
        
        import json
        import os
        
        script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(script_dir)
inventory_file = os.path.join(project_root, "translation_inventory.json")
        if os.path.exists(inventory_file):
            with open(inventory_file, 'r', encoding='utf-8') as f:
                inventory = json.load(f)
            
            for view_id, view_data in inventory['iosViews'].items():
                keys_json = json.dumps(view_data['translationKeys'])
                cursor.execute("""
                    INSERT INTO view_translation_keys_cache 
                    (view_id, view_type, view_path, translation_keys, key_count)
                    VALUES (%s, %s, %s, %s, %s)
                    ON DUPLICATE KEY UPDATE
                    translation_keys = %s,
                    key_count = %s,
                    last_scanned_at = NOW()
                """, (
                    view_id,
                    view_data['viewType'],
                    view_data['viewPath'],
                    keys_json,
                    view_data['keyCount'],
                    keys_json,
                    view_data['keyCount']
                ))
            
            db.commit()
            print(f"   ✓ Populated {len(inventory['iosViews'])} views in cache")
        else:
            print("   ! Inventory file not found - run build_translation_inventory.py first")
        
        # 6. Create index for faster lookups
        print("\n6. Creating indexes for performance...")
        
        # Check and create indexes individually
        try:
            cursor.execute("ALTER TABLE translations ADD INDEX idx_translation_key (translation_key)")
        except:
            pass  # Index might already exist
        
        try:
            cursor.execute("ALTER TABLE translations ADD INDEX idx_language_code (language_code)")
        except:
            pass
        
        try:
            cursor.execute("ALTER TABLE translations ADD INDEX idx_updated_at (updated_at)")
        except:
            pass
        
        db.commit()
        print("   ✓ Indexes created")
        
        print("\n" + "=" * 70)
        print("✓ All migrations completed successfully!")
        print("=" * 70)
        
        # Print summary
        cursor.execute("SELECT COUNT(*) as count FROM translations")
        total_keys = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) as count FROM translation_history")
        history_records = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) as count FROM view_translation_keys_cache")
        cached_views = cursor.fetchone()[0]
        
        print(f"\n📊 Summary:")
        print(f"   Total translation keys: {total_keys}")
        print(f"   History records: {history_records}")
        print(f"   Cached views: {cached_views}")
        
    except Exception as e:
        print(f"\n❌ Error: {str(e)}")
        db.rollback()
        raise
    finally:
        cursor.close()
        db.close()

if __name__ == "__main__":
    run_migrations()
