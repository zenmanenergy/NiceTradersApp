#!/usr/bin/env python3
"""
Situation 4: Buyer Proposed Location - Seller Not Yet Responded

Expected Dashboard Display:
- BUYER: "⏳ Waiting for Location Approval" - Orange, "Waiting for seller to accept IKEA"
- SELLER: "🎯 Action Required" - Red, "Accept or counter location: IKEA"
"""

from setup_base import (
    connect_db, cleanup_test_data, setup_users_and_listing,
    display_status, LISTING_ID, BUYER_ID, SELLER_ID
)
from datetime import datetime, timedelta

def setup_situation_4():
    db = connect_db()
    
    try:
        # Step 1: Clean up
        cleanup_test_data(db)
        
        # Step 2: Create users and listing
        setup_users_and_listing(db)
        
        # Step 3: Create and accept time proposal
        cursor = db.cursor()
        meeting_time = (datetime.now() + timedelta(days=1)).strftime('%Y-%m-%d 10:00:00')
        now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        
        cursor.execute("""
            INSERT INTO listing_meeting_time (
                time_negotiation_id, listing_id, buyer_id, proposed_by,
                meeting_time, accepted_at, rejected_at
            )
            VALUES (UUID(), %s, %s, %s, %s, %s, NULL)
        """, (LISTING_ID, BUYER_ID, BUYER_ID, meeting_time, now))
        
        # Step 4: Create payment record with both parties paid
        import uuid
        cursor.execute("""
            INSERT INTO listing_payments (payment_id, listing_id, buyer_id, buyer_paid_at, seller_paid_at)
            VALUES (%s, %s, %s, %s, %s)
        """, (str(uuid.uuid4()), LISTING_ID, BUYER_ID, now, now))
        
        # Step 5: Create location proposal (buyer proposes IKEA)
        cursor.execute("""
            INSERT INTO listing_meeting_location (
                location_negotiation_id, listing_id, buyer_id, proposed_by,
                meeting_location_lat, meeting_location_lng, meeting_location_name,
                accepted_at, rejected_at
            )
            VALUES (UUID(), %s, %s, %s, %s, %s, %s, NULL, NULL)
        """, (LISTING_ID, BUYER_ID, BUYER_ID, 37.7827819, -122.4086487, 'IKEA'))
        
        db.commit()
        cursor.close()
        
        print("\n" + "="*70)
        print("SITUATION 4: BUYER PROPOSED LOCATION - SELLER NOT YET RESPONDED")
        print("="*70)
        
        display_status(db)
        
        print("\n📱 Expected Dashboard Views:")
        print("   BUYER:  '⏳ Waiting for Location Approval' (Orange)")
        print("            Message: 'Waiting for seller to accept IKEA'")
        print("   SELLER: '🎯 Action Required' (Red)")
        print("            Message: 'Accept or counter location: IKEA'")
        print("\n🎯 ACTION: Refresh iOS app and verify location proposal is visible")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == '__main__':
    setup_situation_4()
