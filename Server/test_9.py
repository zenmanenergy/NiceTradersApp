#!/usr/bin/env python3
"""
Test State 9: Seller accepts location
Sets listing_meeting_location.accepted_at to current timestamp
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
    # Get current location negotiation
    cursor.execute("""
        SELECT location_negotiation_id, meeting_location_name FROM listing_meeting_location
        WHERE listing_id = %s
    """, (listing_id,))
    
    location_neg = cursor.fetchone()
    
    if not location_neg:
        print("❌ No location negotiation found for this listing")
        exit(1)
    
    # Accept the location
    cursor.execute("""
        UPDATE listing_meeting_location
        SET accepted_at = NOW(), updated_at = NOW()
        WHERE listing_id = %s
    """, (listing_id,))
    
    db.commit()
    
    print("✅ Test State 9: Seller accepts location")
    print(f"   location_negotiation_id: {location_neg['location_negotiation_id']}")
    print(f"   listing_id: {listing_id}")
    print(f"   meeting_location_name: {location_neg['meeting_location_name']}")
    print(f"   accepted_at: NOW()")
    
except Exception as e:
    print(f"❌ Error: {str(e)}")
    import traceback
    traceback.print_exc()
finally:
    cursor.close()
    db.close()
