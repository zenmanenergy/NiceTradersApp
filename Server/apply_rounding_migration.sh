#!/bin/bash

# Migration script for adding willRoundToNearestDollar preference to listings table
# Usage: ./apply_rounding_migration.sh

cd "$(dirname "$0")"

echo "Applying rounding preference migration..."

venv/bin/python3 << 'EOF'
import pymysql
import sys

try:
    db = pymysql.connect(
        host='localhost',
        user='stevenelson',
        password='mwitcitw711',
        database='nicetraders'
    )
    cursor = db.cursor()
    
    with open('migrations/007_add_rounding_preference.sql', 'r') as f:
        sql_content = f.read()
        statements = [s.strip() for s in sql_content.split(';') if s.strip()]
        
        for statement in statements:
            print(f'Executing: {statement[:70]}...')
            cursor.execute(statement)
    
    db.commit()
    cursor.close()
    db.close()
    
    print('✓ Migration applied successfully')
    sys.exit(0)
    
except Exception as e:
    print(f'✗ Migration failed: {str(e)}')
    sys.exit(1)
EOF
