#!/usr/bin/env python3
"""
Test State 3: Buyer has paid, seller has not paid
Sets listing_payments.buyer_paid_at to current timestamp, seller_paid_at = NULL
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
    # First, delete all PayPal orders for this listing and user
    test_user_id = 'USR53a3c642-4914-4de8-8217-03ee3da42224'
    cursor.execute("""
        DELETE FROM paypal_orders
        WHERE listing_id = %s AND user_id = %s
    """, (listing_id, test_user_id))
    deleted_count = cursor.rowcount
    
    # Check if payment record exists
    cursor.execute("""
        SELECT payment_id FROM listing_payments
        WHERE listing_id = %s
    """, (listing_id,))
    
    payment = cursor.fetchone()
    
    if payment:
        # Update existing payment record: buyer paid, seller NOT paid
        cursor.execute("""
            UPDATE listing_payments
            SET buyer_paid_at = NOW(), buyer_transaction_id = %s, seller_paid_at = NULL, seller_transaction_id = NULL, updated_at = NOW()
            WHERE listing_id = %s
        """, ('5V73953924153452L', listing_id))
    else:
        # Create new payment record
        payment_id = f"PAY-{uuid.uuid4().hex[:35]}"
        cursor.execute("""
            INSERT INTO listing_payments
            (payment_id, listing_id, buyer_id, buyer_paid_at, buyer_transaction_id, created_at, updated_at)
            VALUES (%s, %s, %s, NOW(), %s, NOW(), NOW())
        """, (payment_id, listing_id, "USR387e9549-3339-4ea1-b0d2-f6a66c25c390", '5V73953924153452L'))
    
    db.commit()
    
    print("✅ Test State 3: Buyer has paid, seller has not paid")
    print(f"   Deleted {deleted_count} PayPal orders")
    print(f"   listing_id: {listing_id}")
    print(f"   buyer_paid_at: NOW()")
    print(f"   buyer_transaction_id: 5V73953924153452L")
    print(f"   seller_paid_at: NULL")
    
except Exception as e:
    print(f"❌ Error: {str(e)}")
    import traceback
    traceback.print_exc()
finally:
    cursor.close()
    db.close()
