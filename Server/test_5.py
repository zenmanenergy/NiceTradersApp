#!/usr/bin/env python3
"""
Test State 5: Both buyer and seller have paid
Sets listing_payments.buyer_paid_at and seller_paid_at to current timestamp
"""

import pymysql
import pymysql.cursors
import uuid

# Test values
listing_id = '1ed56571-d1db-4c68-b487-a05b8ac84b54'

# Connect to database
db = pymysql.connect(
    host='localhost',
    user='stevenelson',
    password='mwitcitw711',
    database='nicetraders',
    cursorclass=pymysql.cursors.DictCursor
)
cursor = db.cursor()

try:
    # Check if payment record exists
    cursor.execute("""
        SELECT payment_id FROM listing_payments
        WHERE listing_id = %s
    """, (listing_id,))
    
    payment = cursor.fetchone()
    
    if payment:
        # Update existing payment record
        cursor.execute("""
            UPDATE listing_payments
            SET buyer_paid_at = NOW(), seller_paid_at = NOW(), updated_at = NOW()
            WHERE listing_id = %s
        """, (listing_id,))
    else:
        # Create new payment record
        payment_id = f"PAY-{uuid.uuid4().hex[:35]}"
        cursor.execute("""
            INSERT INTO listing_payments
            (payment_id, listing_id, buyer_id, buyer_paid_at, seller_paid_at, created_at, updated_at)
            VALUES (%s, %s, %s, NOW(), NOW(), NOW(), NOW())
        """, (payment_id, listing_id, "USR387e9549-3339-4ea1-b0d2-f6a66c25c390"))
    
    db.commit()
    
    print("✅ Test State 5: Both buyer and seller have paid")
    print(f"   listing_id: {listing_id}")
    print(f"   buyer_paid_at: NOW()")
    print(f"   seller_paid_at: NOW()")
    
except Exception as e:
    print(f"❌ Error: {str(e)}")
    import traceback
    traceback.print_exc()
finally:
    cursor.close()
    db.close()
