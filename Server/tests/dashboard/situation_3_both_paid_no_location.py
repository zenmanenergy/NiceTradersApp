#!/usr/bin/env python3
"""
Situation 3: Both Paid - Before Location Proposed

Expected Dashboard Display:
- BUYER: "✅ Ready to Meet" - Green map pin, "Propose a meeting location"
- SELLER: "✅ Ready to Meet" - Green map pin, "Waiting for location proposal"
"""

from setup_base import (
    connect_db, cleanup_test_data, setup_users_and_listing,
    display_status, LISTING_ID, BUYER_ID, SELLER_ID
)
from datetime import datetime, timedelta

def setup_situation_3():
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
        
        db.commit()
        cursor.close()
        
        print("\n" + "="*70)
        print("SITUATION 3: BOTH PAID - BEFORE LOCATION PROPOSED")
        print("="*70)
        
        display_status(db)
        
        print("\n📱 Expected Dashboard Views:")
        print("   BUYER:  '✅ Ready to Meet' (Green, Map Pin)")
        print("            Action: Propose a meeting location")
        print("   SELLER: '✅ Ready to Meet' (Green, Map Pin)")
        print("            Message: Waiting for location proposal")
        print("\n🎯 ACTION: Refresh iOS app and verify both can see 'Ready to Meet' status")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == '__main__':
    setup_situation_3()
