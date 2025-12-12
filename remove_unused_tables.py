#!/usr/bin/env python3
"""
Script to remove unused tables from the NiceTradersApp database:
- exchange_offers
- exchange_transactions
- user_favorites
"""

import pymysql
import sys

def remove_unused_tables():
    """Remove unused exchange and favorites tables from database"""
    try:
        # Connect to database
        db = pymysql.connect(
            host='localhost',
            user='stevenelson',
            password='mwitcitw711',
            database='nicetraders'
        )
        cursor = db.cursor()
        
        print("Attempting to remove unused tables from nicetraders database...")
        print("-" * 60)
        
        # Tables to remove (in order of dependencies)
        tables_to_remove = [
            'exchange_transactions',  # Has FK to exchange_offers, must come first
            'exchange_offers',        # Has FK to listings
            'user_favorites'          # Has FK to listings and users
        ]
        
        removed_tables = []
        
        for table_name in tables_to_remove:
            try:
                # Check if table exists
                cursor.execute(f"SHOW TABLES LIKE '{table_name}'")
                result = cursor.fetchone()
                
                if result:
                    # Drop the table
                    cursor.execute(f"DROP TABLE {table_name}")
                    db.commit()
                    removed_tables.append(table_name)
                    print(f"✅ Dropped table: {table_name}")
                else:
                    print(f"ℹ️  Table does not exist: {table_name}")
                    
            except pymysql.Error as e:
                print(f"❌ Error dropping {table_name}: {e}")
                db.rollback()
                return False
        
        cursor.close()
        db.close()
        
        print("-" * 60)
        print(f"\n✅ SUCCESS: Removed {len(removed_tables)} table(s)")
        if removed_tables:
            print(f"   Tables removed: {', '.join(removed_tables)}")
        
        return True
        
    except pymysql.Error as e:
        print(f"❌ ERROR: Database connection failed: {e}")
        return False
    except Exception as e:
        print(f"❌ ERROR: {e}")
        return False

if __name__ == "__main__":
    success = remove_unused_tables()
    sys.exit(0 if success else 1)
