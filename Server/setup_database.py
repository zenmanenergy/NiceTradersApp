#!/usr/bin/env python3
"""
Database Setup Script for NiceTradersApp
Verifies connection and creates all tables and indexes
"""

import pymysql
import pymysql.cursors
import sys

# Database connection details
DB_CONFIG = {
    'host': 'localhost',
    'user': 'stevenelson',
    'password': 'mwitcitw711',
    'database': 'nicetraders',
    'cursorclass': pymysql.cursors.DictCursor
}

def test_connection():
    """Test database connection"""
    try:
        print("Testing database connection...")
        connection = pymysql.connect(**DB_CONFIG)
        cursor = connection.cursor()
        cursor.execute("SELECT VERSION()")
        version = cursor.fetchone()
        print(f"✅ Successfully connected to MySQL {version['VERSION()']}")
        cursor.execute("SELECT DATABASE()")
        db = cursor.fetchone()
        print(f"✅ Using database: {db['DATABASE()']}")
        connection.close()
        return True
    except Exception as e:
        print(f"❌ Connection failed: {str(e)}")
        return False

def create_tables():
    """Create all database tables"""
    try:
        print("\n" + "="*60)
        print("Creating database tables...")
        print("="*60 + "\n")
        
        connection = pymysql.connect(**DB_CONFIG)
        cursor = connection.cursor()
        
        # Read the schema file
        with open('database_schema.sql', 'r') as f:
            schema_sql = f.read()
        
        # Parse SQL statements properly, preserving inline comments
        statements = []
        current_statement = []
        in_statement = False
        
        for line in schema_sql.split('\n'):
            stripped = line.strip()
            
            # Skip standalone comment lines and empty lines
            if not stripped or (stripped.startswith('--') and not in_statement):
                continue
            
            # Start tracking a statement
            if not in_statement and stripped and not stripped.startswith('--'):
                in_statement = True
            
            if in_statement:
                current_statement.append(line)
                if ';' in line:
                    # Found end of statement
                    stmt = '\n'.join(current_statement)
                    statements.append(stmt)
                    current_statement = []
                    in_statement = False
        
        # Execute each statement
        for statement in statements:
            statement = statement.strip()
            if not statement or statement.upper().startswith('SELECT'):
                continue
            
            try:
                cursor.execute(statement)
                # Get the statement type for logging
                stmt_parts = statement.split()
                if len(stmt_parts) > 2:
                    stmt_type = stmt_parts[0].upper()
                    if stmt_type == 'CREATE' and 'TABLE' in statement.upper():
                        table_name = stmt_parts[2]
                        print(f"✅ Created table: {table_name}")
                    elif stmt_type == 'DROP' and 'TABLE' in statement.upper():
                        # DROP TABLE IF EXISTS tablename
                        table_name = stmt_parts[4] if len(stmt_parts) > 4 else stmt_parts[2]
                        print(f"🗑️  Dropped table: {table_name}")
            except pymysql.Error as e:
                error_msg = str(e)
                if 'already exists' not in error_msg.lower() and "doesn't exist" not in error_msg.lower():
                    print(f"⚠️  Error: {error_msg[:200]}")
                    # Show first few words of the statement
                    stmt_preview = ' '.join(statement.split()[:15])
                    print(f"    Statement: {stmt_preview}...")
        
        connection.commit()
        
        # Verify tables were created
        cursor.execute("SHOW TABLES")
        tables = cursor.fetchall()
        
        print("\n" + "="*60)
        print(f"Database setup complete! Total tables: {len(tables)}")
        print("="*60 + "\n")
        print("Tables created:")
        for table in tables:
            table_name = list(table.values())[0]
            cursor.execute(f"SELECT COUNT(*) as count FROM {table_name}")
            count = cursor.fetchone()['count']
            print(f"  • {table_name} ({count} rows)")
        
        connection.close()
        return True
        
    except FileNotFoundError:
        print("❌ Error: database_schema.sql file not found")
        return False
    except Exception as e:
        print(f"❌ Error creating tables: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

def main():
    """Main execution"""
    print("\n" + "="*60)
    print("NiceTradersApp Database Setup")
    print("="*60 + "\n")
    
    # Test connection
    if not test_connection():
        print("\n❌ Setup aborted - connection failed")
        sys.exit(1)
    
    # Create tables
    if create_tables():
        print("\n✅ Database setup completed successfully!")
        sys.exit(0)
    else:
        print("\n❌ Database setup failed")
        sys.exit(1)

if __name__ == "__main__":
    main()
