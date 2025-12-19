#!/usr/bin/env python3
"""
Generate ALTER TABLE statements for schema updates instead of CREATE TABLE.
This allows updating existing tables without errors.
"""

import pymysql
import sys

def get_current_columns(cursor, table_name):
    """Get existing columns for a table"""
    cursor.execute(f"DESCRIBE {table_name}")
    return {row[0]: row[1] for row in cursor.fetchall()}

def get_current_keys(cursor, table_name):
    """Get existing keys/constraints for a table"""
    cursor.execute(f"""
        SELECT CONSTRAINT_NAME, COLUMN_NAME 
        FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE 
        WHERE TABLE_NAME = '{table_name}' AND TABLE_SCHEMA = 'nicetraders'
    """)
    return {row[0]: row[1] for row in cursor.fetchall()}

try:
    db = pymysql.connect(
        host='localhost',
        user='stevenelson',
        password='mwitcitw711',
        database='nicetraders'
    )
    cursor = db.cursor()

    # Check which tables exist
    cursor.execute("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'nicetraders'")
    existing_tables = {row[0] for row in cursor.fetchall()}
    
    print(f"Found {len(existing_tables)} existing tables")
    print("Existing tables:", ', '.join(sorted(existing_tables)))
    
    cursor.close()
    db.close()

except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
