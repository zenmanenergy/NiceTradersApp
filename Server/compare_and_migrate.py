#!/usr/bin/env python3
"""
Compare server database with schema file and show differences
Then migrate the database to match the schema
"""

import pymysql
import pymysql.cursors

def get_server_structure():
    """Get current server database structure"""
    db = pymysql.connect(
        host='localhost',
        user='stevenelson',
        password='mwitcitw711',
        database='nicetraders',
        cursorclass=pymysql.cursors.DictCursor
    )
    cursor = db.cursor()
    
    cursor.execute("SHOW TABLES")
    tables = [list(row.values())[0] for row in cursor.fetchall()]
    
    structure = {}
    for table_name in tables:
        cursor.execute(f"DESCRIBE `{table_name}`")
        columns = cursor.fetchall()
        structure[table_name] = {col['Field']: col for col in columns}
    
    cursor.close()
    db.close()
    return structure

def get_schema_tables():
    """Get tables defined in schema file"""
    # These are the tables that SHOULD exist according to database_schema.sql
    return [
        'users', 'user_settings', 'usersessions', 'history', 'listings',
        'exchange_offers', 'exchange_transactions', 'user_favorites',
        'contact_access', 'messages', 'notifications', 'listing_reports',
        'admin_notifications', 'transactions', 'user_ratings', 'exchange_rates',
        'meeting_proposals', 'exchange_rate_logs', 'exchange_history',
        'translations', 'user_devices', 'apn_logs'
    ]

def get_schema_columns():
    """Get expected columns for each table from schema"""
    # Based on database_schema.sql
    return {
        'transactions': {
            'transaction_id': 'CHAR(39) PRIMARY KEY',
            'user_id': 'CHAR(39) NOT NULL',
            'listing_id': 'CHAR(39) NULL',
            'amount': 'DECIMAL(15,2) NOT NULL',
            'currency': 'VARCHAR(10) NOT NULL',
            'transaction_type': "ENUM('contact_fee', 'listing_fee', 'withdrawal', 'refund') NOT NULL",
            'status': "ENUM('pending', 'completed', 'failed', 'cancelled', 'refunded') DEFAULT 'pending'",
            'payment_method': 'VARCHAR(50) NULL',
            'gateway_transaction_id': 'VARCHAR(255) NULL',
            'description': 'TEXT NULL',
            'created_at': 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP',
            'completed_at': 'TIMESTAMP NULL'
        }
    }

def migrate_database():
    """Add missing columns to match schema"""
    print("="*70)
    print("DATABASE MIGRATION")
    print("="*70)
    
    server_structure = get_server_structure()
    schema_tables = get_schema_tables()
    schema_columns = get_schema_columns()
    
    # Check for extra tables (not in schema)
    extra_tables = set(server_structure.keys()) - set(schema_tables)
    if extra_tables:
        print(f"\n⚠️  Extra tables on server (not in schema):")
        for table in extra_tables:
            print(f"  - {table}")
    
    # Check for missing tables (in schema but not on server)
    missing_tables = set(schema_tables) - set(server_structure.keys())
    if missing_tables:
        print(f"\n⚠️  Missing tables (in schema but not on server):")
        for table in missing_tables:
            print(f"  - {table}")
    
    # Check for column differences
    print("\n" + "="*70)
    print("COLUMN ANALYSIS")
    print("="*70)
    
    db = pymysql.connect(
        host='localhost',
        user='stevenelson',
        password='mwitcitw711',
        database='nicetraders'
    )
    cursor = db.cursor()
    
    columns_added = 0
    
    # Check transactions table specifically
    if 'transactions' in server_structure and 'transactions' in schema_columns:
        table = 'transactions'
        server_cols = set(server_structure[table].keys())
        schema_cols = set(schema_columns[table].keys())
        
        extra_cols = server_cols - schema_cols
        missing_cols = schema_cols - server_cols
        
        print(f"\nTable: {table}")
        if extra_cols:
            print(f"  Extra columns on server: {', '.join(extra_cols)}")
        if missing_cols:
            print(f"  Missing columns: {', '.join(missing_cols)}")
            # Add missing columns
            for col in missing_cols:
                col_def = schema_columns[table][col]
                try:
                    sql = f"ALTER TABLE `{table}` ADD COLUMN `{col}` {col_def}"
                    print(f"  Adding column {col}...")
                    cursor.execute(sql)
                    db.commit()
                    columns_added += 1
                    print(f"  ✓ Added {col}")
                except Exception as e:
                    print(f"  ✗ Error adding {col}: {e}")
        if not extra_cols and not missing_cols:
            print(f"  ✓ Table matches schema")
    
    cursor.close()
    db.close()
    
    print("\n" + "="*70)
    print("SUMMARY")
    print("="*70)
    print(f"Columns added: {columns_added}")
    print(f"Extra tables: {len(extra_tables)}")
    print(f"Missing tables: {len(missing_tables)}")
    
    if extra_tables:
        print(f"\nNOTE: The following tables exist on server but not in schema:")
        print(f"      {', '.join(extra_tables)}")
        print(f"      These tables will NOT be modified or deleted.")
    
    print("\n✓ Migration complete!")

if __name__ == "__main__":
    try:
        migrate_database()
    except Exception as e:
        print(f"\n✗ Error: {e}")
        import traceback
        traceback.print_exc()
        import sys
        sys.exit(1)
