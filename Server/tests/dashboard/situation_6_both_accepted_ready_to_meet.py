#!/usr/bin/env python3
"""
Situation 6: Both Time and Location Accepted - Ready to Meet

Expected Dashboard Display:
- BUYER: "✅ Ready to Meet" - Green checkmark, displays time and location
- SELLER: "✅ Ready to Meet" - Green checkmark, displays time and location
- Both can see "MARK EXCHANGE COMPLETE" button
"""

from setup_base import (
    connect_db, cleanup_test_data, setup_users_and_listing,
    display_status, LISTING_ID, BUYER_ID, SELLER_ID
)
from datetime import datetime, timedelta

def setup_situation_6():
    db = connect_db()
    
    try:
        # Step 1: Clean up
        cleanup_test_data(db)
        
        # Step 2: Create users and listing
        setup_users_and_listing(db)
        
        # Step 3: Create and accept time proposal
        cursor = db.cursor()
        meeting_time = (datetime.now() + timedelta(days=1)).strftime('%Y-%m-%d 10:00:00')
        time_accepted = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        
        cursor.execute("""
            INSERT INTO listing_meeting_time (
                time_negotiation_id, listing_id, buyer_id, proposed_by,
                meeting_time, accepted_at, rejected_at
            )
            VALUES (UUID(), %s, %s, %s, %s, %s, NULL)
        """, (LISTING_ID, BUYER_ID, BUYER_ID, meeting_time, time_accepted))
        
        # Step 4: Create payment record with both parties paid
        now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        import uuid
        cursor.execute("""
            INSERT INTO listing_payments (payment_id, listing_id, buyer_id, buyer_paid_at, seller_paid_at)
            VALUES (%s, %s, %s, %s, %s)
        """, (str(uuid.uuid4()), LISTING_ID, BUYER_ID, now, now))
        
        # Step 5: Create and accept location proposal
        location_accepted = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        cursor.execute("""
            INSERT INTO listing_meeting_location (
                location_negotiation_id, listing_id, buyer_id, proposed_by,
                meeting_location_lat, meeting_location_lng, meeting_location_name,
                accepted_at, rejected_at
            )
            VALUES (UUID(), %s, %s, %s, %s, %s, %s, %s, NULL)
        """, (LISTING_ID, BUYER_ID, BUYER_ID, 37.7827819, -122.4086487, 'IKEA', location_accepted))
        
        db.commit()
        cursor.close()
        
        print("\n" + "="*70)
        print("SITUATION 6: BOTH TIME AND LOCATION ACCEPTED - READY TO MEET")
        print("="*70)
        
        display_status(db)
        
        print("\n📱 Expected Dashboard Views:")
        print("   BOTH:   '✅ Ready to Meet' (Green, Checkmark)")
        print("            Time: 2025-12-14 10:00:00")
        print("            Location: IKEA")
        print("            Action: 'MARK EXCHANGE COMPLETE' button visible")
        print("\n🎯 ACTION: Refresh iOS app and verify both can see complete meeting details")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == '__main__':
    setup_situation_6()
