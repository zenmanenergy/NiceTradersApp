#!/usr/bin/env python3
"""
Test State 0: Reset all negotiation data
Removes all time proposals, location proposals, and payments for the listing
Allows starting fresh with test_1
"""

import pymysql
import pymysql.cursors

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
    print("🟠 Test State 0: Reset all negotiation data")
    print(f"   listing_id: {listing_id}")
    
    # Delete location proposals
    cursor.execute("""
        DELETE FROM listing_meeting_location
        WHERE listing_id = %s
    """, (listing_id,))
    location_count = cursor.rowcount
    print(f"   ✅ Deleted {location_count} location proposal(s)")
    
    # Delete time proposals
    cursor.execute("""
        DELETE FROM listing_meeting_time
        WHERE listing_id = %s
    """, (listing_id,))
    time_count = cursor.rowcount
    print(f"   ✅ Deleted {time_count} time proposal(s)")
    
    # Delete payments
    cursor.execute("""
        DELETE FROM listing_payments
        WHERE listing_id = %s
    """, (listing_id,))
    payment_count = cursor.rowcount
    print(f"   ✅ Deleted {payment_count} payment record(s)")
    
    # Delete paypal orders for both users
    cursor.execute("""
        DELETE FROM paypal_orders
        WHERE listing_id = %s
    """, (listing_id,))
    paypal_count = cursor.rowcount
    print(f"   ✅ Deleted {paypal_count} PayPal order(s)")
    
    db.commit()
    
    print(f"\n✅ Test State 0: Complete - All negotiation data reset for listing {listing_id}")
    print("   Ready to start fresh with test_1.py")
    
except Exception as e:
    print(f"❌ Error: {str(e)}")
    import traceback
    traceback.print_exc()
finally:
    cursor.close()
    db.close()
