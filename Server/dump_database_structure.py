#!/usr/bin/env python3
"""
Dump current database structure for comparison
"""

import pymysql
import pymysql.cursors

# Database connection details
DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': 'root',
    'database': 'nicetraders',
    'cursorclass': pymysql.cursors.DictCursor
}

def dump_database_structure():
    """Dump all tables and their columns"""
    db = pymysql.connect(**DB_CONFIG)
    cursor = db.cursor()
    
    # Get all tables
    cursor.execute("SHOW TABLES")
    tables = [list(row.values())[0] for row in cursor.fetchall()]
    
    print("="*70)
    print(f"DATABASE STRUCTURE DUMP")
    print(f"Database: {DB_CONFIG['database']}")
    print(f"Total tables: {len(tables)}")
    print("="*70)
    
    for table_name in sorted(tables):
        print(f"\nTable: {table_name}")
        print("-" * 70)
        
        # Get column information
        cursor.execute(f"DESCRIBE `{table_name}`")
        columns = cursor.fetchall()
        
        print(f"{'Column':<30} {'Type':<25} {'Null':<6} {'Key':<6} {'Default':<15}")
        print("-" * 70)
        
        for col in columns:
            null_val = col['Null']
            key_val = col['Key'] if col['Key'] else ''
            default_val = str(col['Default']) if col['Default'] is not None else 'NULL'
            print(f"{col['Field']:<30} {col['Type']:<25} {null_val:<6} {key_val:<6} {default_val:<15}")
    
    cursor.close()
    db.close()

if __name__ == "__main__":
    dump_database_structure()
