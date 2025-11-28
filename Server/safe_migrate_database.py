#!/usr/bin/env python3
"""
Safe Database Migration Script
Compares current database structure with desired schema and:
1. Adds missing tables
2. Adds missing columns to existing tables
3. Does NOT drop or modify existing data

Usage:
  python3 safe_migrate_database.py                                    # Use default localhost
  python3 safe_migrate_database.py --host SERVER_IP --user USER --password PASS --database DB
"""

import pymysql
import pymysql.cursors
import re
from datetime import datetime
import argparse

# Default database connection details (can be overridden by command line)
DB_CONFIG = {
    'host': 'localhost',
    'user': 'stevenelson',
    'password': 'mwitcitw711',
    'database': 'nicetraders',
    'cursorclass': pymysql.cursors.DictCursor
}

def connect_db():
    """Connect to the database"""
    return pymysql.connect(**DB_CONFIG)

def get_existing_tables(cursor):
    """Get list of all existing tables in the database"""
    cursor.execute("SHOW TABLES")
    tables = [list(row.values())[0] for row in cursor.fetchall()]
    return tables

def get_table_columns(cursor, table_name):
    """Get all columns for a specific table"""
    cursor.execute(f"DESCRIBE `{table_name}`")
    columns = {row['Field']: row for row in cursor.fetchall()}
    return columns

def parse_create_table_statements(schema_file_path):
    """Parse CREATE TABLE statements from schema file"""
    with open(schema_file_path, 'r') as f:
        schema_sql = f.read()
    
    # Remove comments and normalize whitespace
    schema_sql = re.sub(r'--.*?\n', '\n', schema_sql)
    
    # Find all CREATE TABLE statements
    table_pattern = r'CREATE TABLE(?:\s+IF NOT EXISTS)?\s+`?(\w+)`?\s*\((.*?)\)\s*(?:ENGINE=\w+)?(?:\s+DEFAULT\s+CHARSET=\w+)?;'
    matches = re.finditer(table_pattern, schema_sql, re.IGNORECASE | re.DOTALL)
    
    tables = {}
    for match in matches:
        table_name = match.group(1)
        table_body = match.group(2)
        
        # Parse columns from table body
        columns = parse_columns_from_table_body(table_body)
        tables[table_name] = {
            'full_definition': match.group(0),
            'columns': columns
        }
    
    return tables

def parse_columns_from_table_body(table_body):
    """Parse column definitions from table body"""
    columns = {}
    lines = [line.strip() for line in table_body.split('\n')]
    
    for line in lines:
        line = line.strip().rstrip(',')
        if not line:
            continue
        
        # Skip constraints and indexes
        if any(keyword in line.upper() for keyword in ['PRIMARY KEY', 'FOREIGN KEY', 'INDEX', 'UNIQUE KEY', 'KEY ', 'CONSTRAINT', 'CHECK']):
            continue
        
        # Parse column definition
        # Format: column_name TYPE [constraints]
        parts = line.split(None, 1)
        if len(parts) >= 2:
            col_name = parts[0].strip('`')
            col_def = parts[1]
            columns[col_name] = col_def
    
    return columns

def create_missing_table(cursor, table_name, table_definition):
    """Create a table that doesn't exist"""
    print(f"\n  Creating table: {table_name}")
    
    # Modify CREATE TABLE to use IF NOT EXISTS for safety
    if 'IF NOT EXISTS' not in table_definition:
        table_definition = table_definition.replace('CREATE TABLE', 'CREATE TABLE IF NOT EXISTS', 1)
    
    try:
        cursor.execute(table_definition)
        print(f"  ✓ Table '{table_name}' created successfully")
        return True
    except Exception as e:
        print(f"  ✗ Error creating table '{table_name}': {e}")
        return False

def add_missing_column(cursor, table_name, column_name, column_definition):
    """Add a missing column to an existing table"""
    print(f"    Adding column: {column_name}")
    
    try:
        # Use ALTER TABLE ADD COLUMN
        sql = f"ALTER TABLE `{table_name}` ADD COLUMN `{column_name}` {column_definition}"
        cursor.execute(sql)
        print(f"    ✓ Column '{column_name}' added to '{table_name}'")
        return True
    except Exception as e:
        print(f"    ✗ Error adding column '{column_name}' to '{table_name}': {e}")
        return False

def migrate_database(schema_file_path):
    """Main migration function"""
    print("="*70)
    print("Safe Database Migration Tool")
    print("="*70)
    print(f"Started at: {datetime.now()}\n")
    
    # Connect to database
    print("Connecting to database...")
    db = connect_db()
    cursor = db.cursor()
    print("✓ Connected\n")
    
    # Get current database state
    print("Analyzing current database structure...")
    existing_tables = get_existing_tables(cursor)
    print(f"✓ Found {len(existing_tables)} existing tables\n")
    
    # Parse desired schema
    print("Parsing schema file...")
    desired_tables = parse_create_table_statements(schema_file_path)
    print(f"✓ Found {len(desired_tables)} tables in schema\n")
    
    # Track changes
    tables_created = 0
    columns_added = 0
    errors = 0
    
    # Process each table in the desired schema
    print("Starting migration...\n")
    
    for table_name, table_info in desired_tables.items():
        print(f"Checking table: {table_name}")
        
        if table_name not in existing_tables:
            # Table doesn't exist - create it
            if create_missing_table(cursor, table_name, table_info['full_definition']):
                tables_created += 1
                db.commit()
        else:
            # Table exists - check for missing columns
            existing_columns = get_table_columns(cursor, table_name)
            desired_columns = table_info['columns']
            
            missing_columns = set(desired_columns.keys()) - set(existing_columns.keys())
            
            if missing_columns:
                print(f"  Found {len(missing_columns)} missing column(s)")
                for col_name in missing_columns:
                    col_def = desired_columns[col_name]
                    if add_missing_column(cursor, table_name, col_name, col_def):
                        columns_added += 1
                        db.commit()
                    else:
                        errors += 1
            else:
                print(f"  ✓ Table is up to date")
    
    # Summary
    print("\n" + "="*70)
    print("Migration Summary")
    print("="*70)
    print(f"Tables created:  {tables_created}")
    print(f"Columns added:   {columns_added}")
    print(f"Errors:          {errors}")
    print(f"Completed at:    {datetime.now()}")
    print("="*70)
    
    cursor.close()
    db.close()
    
    if errors > 0:
        print("\n⚠️  Migration completed with errors. Please review the output above.")
        return False
    else:
        print("\n✓ Migration completed successfully!")
        return True

if __name__ == "__main__":
    import sys
    import os
    
    # Parse command line arguments
    parser = argparse.ArgumentParser(description='Safely migrate database schema')
    parser.add_argument('--host', default='localhost', help='Database host (default: localhost)')
    parser.add_argument('--user', default='stevenelson', help='Database user (default: stevenelson)')
    parser.add_argument('--password', default='mwitcitw711', help='Database password')
    parser.add_argument('--database', default='nicetraders', help='Database name (default: nicetraders)')
    args = parser.parse_args()
    
    # Update DB_CONFIG with command line arguments
    DB_CONFIG['host'] = args.host
    DB_CONFIG['user'] = args.user
    DB_CONFIG['password'] = args.password
    DB_CONFIG['database'] = args.database
    
    # Schema file path - use relative path from script location
    script_dir = os.path.dirname(os.path.abspath(__file__))
    schema_file = os.path.join(script_dir, 'database_schema.sql')
    
    # Check if file exists
    if not os.path.exists(schema_file):
        print(f"Error: Schema file not found at {schema_file}")
        sys.exit(1)
    
    print(f"Connecting to: {args.user}@{args.host}/{args.database}\n")
    
    # Run migration
    try:
        success = migrate_database(schema_file)
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"\n✗ Fatal error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
