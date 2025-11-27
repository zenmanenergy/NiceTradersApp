#!/usr/bin/env python3
"""
Run migration 004: Add negotiation system tables
This script creates the exchange_negotiations, negotiation_history, and user_credits tables
"""

import pymysql
import sys
from pathlib import Path

# Database connection settings
DB_CONFIG = {
    'host': 'localhost',
    'user': 'stevenelson',
    'password': 'mwitcitw711',
    'database': 'nicetraders'
}

def run_migration():
    """Execute the negotiation tables migration"""
    migration_file = Path(__file__).parent / 'migrations' / '004_add_negotiation_tables.sql'
    
    if not migration_file.exists():
        print(f"❌ Migration file not found: {migration_file}")
        sys.exit(1)
    
    print(f"📄 Reading migration file: {migration_file}")
    
    # Read the SQL file
    with open(migration_file, 'r') as f:
        sql_content = f.read()
    
    # Connect to database
    print(f"🔌 Connecting to database: {DB_CONFIG['database']}")
    try:
        db = pymysql.connect(**DB_CONFIG)
        cursor = db.cursor()
        
        # Remove comments and split by semicolons
        lines = []
        for line in sql_content.split('\n'):
            stripped = line.strip()
            # Skip comment lines
            if stripped.startswith('--'):
                continue
            lines.append(line)
        
        clean_sql = '\n'.join(lines)
        
        # Split by semicolon but keep the statement structure
        statements = []
        current_statement = []
        for line in clean_sql.split('\n'):
            current_statement.append(line)
            if line.strip().endswith(';'):
                stmt = '\n'.join(current_statement).strip()
                if stmt and not stmt.startswith('--'):
                    statements.append(stmt)
                current_statement = []
        
        print(f"📝 Executing {len(statements)} SQL statements...")
        
        for i, statement in enumerate(statements, 1):
            # Skip empty statements
            if not statement.strip():
                continue
            
            try:
                cursor.execute(statement)
                # Check if this is a SELECT statement (status message)
                if statement.strip().upper().startswith('SELECT'):
                    result = cursor.fetchone()
                    if result:
                        print(f"   ✅ {result[0]}")
                else:
                    # Extract table name for CREATE/ALTER statements
                    if 'CREATE TABLE' in statement.upper():
                        table_name = statement.split('CREATE TABLE')[1].split('(')[0].strip().split()[0]
                        if 'IF NOT EXISTS' in statement.upper():
                            table_name = statement.split('IF NOT EXISTS')[1].split('(')[0].strip().split()[0]
                        print(f"   ✅ Created table: {table_name}")
                    elif 'ALTER TABLE' in statement.upper():
                        table_name = statement.split('ALTER TABLE')[1].split()[0].strip()
                        print(f"   ✅ Altered table: {table_name}")
                    else:
                        print(f"   ✅ Statement {i} executed")
            except pymysql.err.OperationalError as e:
                # Skip duplicate column/table errors
                if 'Duplicate column name' in str(e) or 'already exists' in str(e):
                    print(f"   ⚠️  Statement {i} skipped (already exists)")
                else:
                    print(f"   ❌ Error: {e}")
                    raise
            except Exception as e:
                print(f"   ❌ Error executing statement {i}: {e}")
                print(f"   Statement: {statement[:100]}...")
                raise
        
        db.commit()
        print("\n✅ Migration 004 completed successfully!")
        print("\n📊 Tables created/modified:")
        print("   - exchange_negotiations (new)")
        print("   - negotiation_history (new)")
        print("   - user_credits (new)")
        print("   - transactions (added negotiation_id column)")
        
        # Verify tables were created
        cursor.execute("SHOW TABLES LIKE 'exchange_negotiations'")
        if cursor.fetchone():
            cursor.execute("DESCRIBE exchange_negotiations")
            columns = cursor.fetchall()
            print(f"\n✅ exchange_negotiations table verified ({len(columns)} columns)")
        
        cursor.execute("SHOW TABLES LIKE 'negotiation_history'")
        if cursor.fetchone():
            cursor.execute("DESCRIBE negotiation_history")
            columns = cursor.fetchall()
            print(f"✅ negotiation_history table verified ({len(columns)} columns)")
        
        cursor.execute("SHOW TABLES LIKE 'user_credits'")
        if cursor.fetchone():
            cursor.execute("DESCRIBE user_credits")
            columns = cursor.fetchall()
            print(f"✅ user_credits table verified ({len(columns)} columns)")
        
        cursor.close()
        db.close()
        
    except pymysql.Error as e:
        print(f"\n❌ Database error: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Unexpected error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    print("=" * 60)
    print("Migration 004: Add Negotiation System Tables")
    print("=" * 60)
    run_migration()
    print("=" * 60)
