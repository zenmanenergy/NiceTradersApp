#!/usr/bin/env python3
"""
Situation 1: Buyer Proposes Time - Seller Not Yet Responded

Expected Dashboard Display:
- BUYER: "⏳ Waiting for Acceptance" - Orange/Yellow hourglass
- SELLER: "🎯 Action Required" - Red alert badge
"""

from setup_base import (
    connect_db, cleanup_test_data, setup_users_and_listing, 
    display_status, LISTING_ID, BUYER_ID, SELLER_ID
)
from datetime import datetime, timedelta

def setup_situation_1():
    db = connect_db()
    
    try:
        # Step 1: Clean up
        cleanup_test_data(db)
        
        # Step 2: Create users and listing
        setup_users_and_listing(db)
        
        # Step 3: Create time proposal (buyer proposes)
        cursor = db.cursor()
        meeting_time = (datetime.now() + timedelta(days=1)).strftime('%Y-%m-%d 10:00:00')
        
        cursor.execute("""
            INSERT INTO listing_meeting_time (
                time_negotiation_id, listing_id, buyer_id, proposed_by,
                meeting_time, accepted_at, rejected_at
            )
            VALUES (UUID(), %s, %s, %s, %s, NULL, NULL)
        """, (LISTING_ID, BUYER_ID, BUYER_ID, meeting_time))
        
        db.commit()
        cursor.close()
        
        print("\n" + "="*70)
        print("SITUATION 1: BUYER PROPOSES TIME - SELLER NOT YET RESPONDED")
        print("="*70)
        
        display_status(db)
        
        print("\n📱 Expected Dashboard Views:")
        print("   BUYER:  '⏳ Waiting for Acceptance' (Orange, Hourglass)")
        print("   SELLER: '🎯 Action Required' (Red, Alert Badge)")
        print("\n🎯 ACTION: Refresh iOS app and verify both views display correctly")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == '__main__':
    setup_situation_1()
