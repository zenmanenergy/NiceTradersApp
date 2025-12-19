#!/usr/bin/env python3
"""
Test State 8: Buyer proposes a location (replaces seller's proposal)
Updates listing_meeting_location with buyer as proposer, resets accepted_at = NULL
Requires: listing_meeting_time.accepted_at must have a value
"""

import pymysql
import pymysql.cursors

# Test values
listing_id = '1ed56571-d1db-4c68-b487-a05b8ac84b54'
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
    
    # Check if location negotiation exists
    cursor.execute("""
        SELECT location_negotiation_id FROM listing_meeting_location
        WHERE listing_id = %s
    """, (listing_id,))
    
    location_neg = cursor.fetchone()
    
    if location_neg:
        # Update existing - buyer proposes new location, resets acceptance
        cursor.execute("""
            UPDATE listing_meeting_location
            SET proposed_by = %s,
                meeting_location_lat = %s,
                meeting_location_lng = %s,
                meeting_location_name = %s,
                accepted_at = NULL,
                rejected_at = NULL,
                updated_at = NOW()
            WHERE listing_id = %s
        """, (buyer_id, meeting_lat, meeting_lng, location_name, listing_id))
        
        print("✅ Test State 8: Buyer proposes a location (replacing seller's proposal)")
        print(f"   location_negotiation_id: {location_neg['location_negotiation_id']}")
    else:
        print("❌ No location negotiation found. Run test_state_6 first to have seller propose.")
        exit(1)
    
    db.commit()
    
    print(f"   listing_id: {listing_id}")
    print(f"   proposed_by: {buyer_id} (buyer)")
    print(f"   meeting_location_lat: {meeting_lat}")
    print(f"   meeting_location_lng: {meeting_lng}")
    print(f"   meeting_location_name: {location_name}")
    print(f"   accepted_at: NULL (reset)")
    
except Exception as e:
    print(f"❌ Error: {str(e)}")
    import traceback
    traceback.print_exc()
finally:
    cursor.close()
    db.close()
