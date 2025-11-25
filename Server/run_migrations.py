#!/usr/bin/env python3
"""
Migration runner for translations table
"""

import pymysql
import pymysql.cursors
import sys
import os

# Database connection details
DB_CONFIG = {
    'host': 'localhost',
    'user': 'stevenelson',
    'password': 'mwitcitw711',
    'database': 'nicetraders',
    'cursorclass': pymysql.cursors.DictCursor
}

def run_migration():
    """Run the translations table migration"""
    try:
        print("Running migrations...")
        connection = pymysql.connect(**DB_CONFIG)
        cursor = connection.cursor()
        
        # Read migration file
        migration_file = os.path.join(os.path.dirname(__file__), 'migrations', 'create_translations_table.sql')
        with open(migration_file, 'r') as f:
            sql = f.read()
        
        # Execute each statement
        for statement in sql.split(';'):
            statement = statement.strip()
            if statement:
                cursor.execute(statement)
                print(f"✅ Executed: {statement[:80]}...")
        
        connection.commit()
        
        # Verify table exists
        cursor.execute("SHOW TABLES LIKE 'translations'")
        if cursor.fetchone():
            print("\n✅ Translations table created successfully!")
            cursor.execute("DESC translations")
            columns = cursor.fetchall()
            print("\nTable structure:")
            for col in columns:
                print(f"  • {col['Field']} ({col['Type']})")
        else:
            print("\n❌ Translations table was not created")
            return False
        
        connection.close()
        return True
        
    except Exception as e:
        print(f"❌ Migration failed: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    if run_migration():
        sys.exit(0)
    else:
        sys.exit(1)
