#!/bin/bash

# Script to clean up exchange rates table, keeping only the most recent date
# Usage: ./cleanup_exchange_rates.sh

cd "$(dirname "$0")"

echo "Cleaning up exchange rates table (keeping only latest)..."

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
    
    # Get the latest date
    cursor.execute("""
        SELECT MAX(date_retrieved) as latest_date FROM exchange_rates
    """)
    result = cursor.fetchone()
    
    if not result or result[0] is None:
        print('✗ No exchange rates found in database')
        sys.exit(1)
    
    latest_date = result[0]
    print(f'Latest exchange rate date: {latest_date}')
    
    # Delete all rates except the latest
    cursor.execute("""
        DELETE FROM exchange_rates 
        WHERE date_retrieved < %s
    """, (latest_date,))
    
    deleted_count = cursor.rowcount
    db.commit()
    
    # Get remaining count
    cursor.execute("SELECT COUNT(*) FROM exchange_rates")
    remaining = cursor.fetchone()[0]
    
    cursor.close()
    db.close()
    
    print(f'✓ Deleted {deleted_count} old exchange rate records')
    print(f'✓ Kept {remaining} rates from {latest_date}')
    sys.exit(0)
    
except Exception as e:
    print(f'✗ Cleanup failed: {str(e)}')
    sys.exit(1)
EOF
