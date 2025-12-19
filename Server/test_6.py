#!/usr/bin/env python3
"""
Test State 6: Seller proposes a location
Creates a listing_meeting_location row with seller as proposer, accepted_at = NULL
Requires: listing_meeting_time.accepted_at must have a value
"""

import pymysql
import pymysql.cursors
import uuid

# Test values
listing_id = '1ed56571-d1db-4c68-b487-a05b8ac84b54'
seller_id = 'USR53a3c642-4914-4de8-8217-03ee3da42224'
buyer_id = 'USR387e9549-3339-4ea1-b0d2-f6a66c25c390'
meeting_lat = 37.78278190
meeting_lng = -122.40864870
location_name = 'IKEA'

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
    # Verify time is accepted
    cursor.execute("""
        SELECT accepted_at FROM listing_meeting_time
        WHERE listing_id = %s
    """, (listing_id,))
    
    time_neg = cursor.fetchone()
    
    if not time_neg:
        print("❌ No time negotiation found. Run test_state_2 first to accept time.")
        exit(1)
    
    if not time_neg['accepted_at']:
        print("❌ Time negotiation not accepted yet. Run test_state_2 first to accept time.")
        exit(1)
    
    # Check if location negotiation already exists
    cursor.execute("""
        SELECT location_negotiation_id FROM listing_meeting_location
        WHERE listing_id = %s
    """, (listing_id,))
    
    existing = cursor.fetchone()
    
    if existing:
        print(f"⚠️  Location negotiation already exists: {existing['location_negotiation_id']}")
        print("Deleting existing negotiation...")
        cursor.execute("""
            DELETE FROM listing_meeting_location WHERE listing_id = %s
        """, (listing_id,))
        db.commit()
    
    # Create location negotiation with seller proposing
    location_negotiation_id = f"LOC-{uuid.uuid4().hex[:35]}"
    
    cursor.execute("""
        INSERT INTO listing_meeting_location
        (location_negotiation_id, listing_id, buyer_id, proposed_by, 
         meeting_location_lat, meeting_location_lng, meeting_location_name,
         created_at, updated_at)
        VALUES (%s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
    """, (location_negotiation_id, listing_id, buyer_id, seller_id, 
          meeting_lat, meeting_lng, location_name))
    
    db.commit()
    
    print("✅ Test State 6: Seller proposes a location")
    print(f"   location_negotiation_id: {location_negotiation_id}")
    print(f"   listing_id: {listing_id}")
    print(f"   buyer_id: {buyer_id}")
    print(f"   proposed_by: {seller_id} (seller)")
    print(f"   meeting_location_lat: {meeting_lat}")
    print(f"   meeting_location_lng: {meeting_lng}")
    print(f"   meeting_location_name: {location_name}")
    print(f"   accepted_at: NULL")
    
except Exception as e:
    print(f"❌ Error: {str(e)}")
    import traceback
    traceback.print_exc()
finally:
    cursor.close()
    db.close()
