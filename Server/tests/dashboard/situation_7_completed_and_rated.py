#!/usr/bin/env python3
"""
Situation 7: Exchange Completed - Both Rated

Expected Dashboard Display:
- BUYER: "✅ Completed" - Gray (archived), shows rating
- SELLER: "✅ Completed" - Gray (archived), shows rating
- Both moved to "Completed Exchanges" section
"""

from setup_base import (
    connect_db, cleanup_test_data, setup_users_and_listing,
    display_status, LISTING_ID, BUYER_ID, SELLER_ID
)
from datetime import datetime, timedelta

def setup_situation_7():
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
        
        # Step 6: Mark listing as completed
        cursor.execute("""
            UPDATE listings SET status = 'completed' WHERE listing_id = %s
        """, (LISTING_ID,))
        
        # Step 7: Create exchange history records for both users
        exchange_id = str(__import__('uuid').uuid4())
        cursor.execute("""
            INSERT INTO exchange_history (
                ExchangeId, user_id, ExchangeDate, Currency, Amount,
                PartnerName, Rating, Notes, TransactionType
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (exchange_id, BUYER_ID, now, 'USD', 100.00,
              f'{SELLER_FIRST_NAME} {SELLER_LAST_NAME}', 5,
              'Great exchange!', 'buy'))
        
        # Seller's exchange history
        seller_exchange_id = str(__import__('uuid').uuid4())
        cursor.execute("""
            INSERT INTO exchange_history (
                ExchangeId, user_id, ExchangeDate, Currency, Amount,
                PartnerName, Rating, Notes, TransactionType
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (seller_exchange_id, SELLER_ID, now, 'USD', 100.00,
              f'{BUYER_FIRST_NAME} {BUYER_LAST_NAME}', 5,
              'Excellent buyer!', 'sell'))
        
        # Step 8: Create rating records
        cursor.execute("""
            INSERT INTO user_ratings (
                rating_id, user_id, rater_id, rating, review
            )
            VALUES (UUID(), %s, %s, %s, %s)
        """, (SELLER_ID, BUYER_ID, 5, 'Great exchange!'))
        
        cursor.execute("""
            INSERT INTO user_ratings (
                rating_id, user_id, rater_id, rating, review
            )
            VALUES (UUID(), %s, %s, %s, %s)
        """, (BUYER_ID, SELLER_ID, 5, 'Excellent buyer!'))
        
        db.commit()
        cursor.close()
        
        print("\n" + "="*70)
        print("SITUATION 7: EXCHANGE COMPLETED - BOTH RATED")
        print("="*70)
        
        display_status(db)
        
        print("\n📱 Expected Dashboard Views:")
        print("   BUYER:  '✅ Completed' (Gray, Checkmark) - in 'Completed Exchanges' section")
        print("            Rating: 5★")
        print("            Message: 'Great exchange!'")
        print("   SELLER: '✅ Completed' (Gray, Checkmark) - in 'Completed Exchanges' section")
        print("            Rating: 5★ by buyer")
        print("            Message: 'Excellent buyer!'")
        print("\n🎯 ACTION: Refresh iOS app and verify completed exchange appears in archive")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        db.rollback()
    finally:
        db.close()

# Add missing imports at top
SELLER_FIRST_NAME = 'John'
SELLER_LAST_NAME = 'Seller'
BUYER_FIRST_NAME = 'Jane'
BUYER_LAST_NAME = 'Buyer'

if __name__ == '__main__':
    setup_situation_7()
