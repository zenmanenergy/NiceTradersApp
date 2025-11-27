#!/usr/bin/env python3
"""
Verify negotiation tables were created correctly
"""

import pymysql

DB_CONFIG = {
    'host': 'localhost',
    'user': 'stevenelson',
    'password': 'mwitcitw711',
    'database': 'nicetraders'
}

def verify_tables():
    """Verify the negotiation tables exist and show their structure"""
    db = pymysql.connect(**DB_CONFIG)
    cursor = db.cursor()
    
    tables = ['exchange_negotiations', 'negotiation_history', 'user_credits']
    
    print("\n" + "=" * 70)
    print("VERIFYING NEGOTIATION SYSTEM TABLES")
    print("=" * 70)
    
    for table in tables:
        print(f"\n📋 Table: {table}")
        print("-" * 70)
        
        # Check if table exists
        cursor.execute(f"SHOW TABLES LIKE '{table}'")
        if not cursor.fetchone():
            print(f"❌ Table '{table}' does NOT exist!")
            continue
        
        # Get table structure
        cursor.execute(f"DESCRIBE {table}")
        columns = cursor.fetchall()
        
        print(f"✅ Table exists with {len(columns)} columns:\n")
        print(f"{'Column':<35} {'Type':<25} {'Null':<6} {'Key':<6} {'Default':<15}")
        print("-" * 70)
        
        for col in columns:
            field, col_type, null, key, default, extra = col
            default_str = str(default)[:14] if default else 'NULL'
            print(f"{field:<35} {col_type:<25} {null:<6} {key:<6} {default_str:<15}")
    
    # Check if transactions table has negotiation_id column
    print(f"\n📋 Table: transactions (checking negotiation_id column)")
    print("-" * 70)
    cursor.execute("DESCRIBE transactions")
    columns = cursor.fetchall()
    has_negotiation_id = any(col[0] == 'negotiation_id' for col in columns)
    
    if has_negotiation_id:
        print("✅ transactions table has 'negotiation_id' column")
    else:
        print("❌ transactions table is MISSING 'negotiation_id' column")
    
    cursor.close()
    db.close()
    
    print("\n" + "=" * 70)

if __name__ == '__main__':
    verify_tables()
