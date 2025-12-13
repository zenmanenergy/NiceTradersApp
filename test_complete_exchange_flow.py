#!/usr/bin/env python3
"""
Test script to verify the complete exchange and rating flow works end-to-end
"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'Server'))

from Server.Negotiations.CompleteExchange import complete_exchange
from Server.Ratings.SubmitRating import submit_rating
from Server._Lib import Database
import json

def test_complete_exchange_flow():
    """Test the complete exchange workflow"""
    
    print("\n" + "="*60)
    print("TESTING COMPLETE EXCHANGE FLOW")
    print("="*60)
    
    # Connect to database
    cursor, connection = Database.ConnectToDatabase()
    
    try:
        # Find a listing with both time and location agreements, and payments from both parties
        cursor.execute("""
            SELECT DISTINCT 
                l.listing_id,
                l.currency,
                l.amount,
                lmt.buyer_id,
                l.user_id as seller_id
            FROM listings l
            JOIN listing_meeting_time lmt ON l.listing_id = lmt.listing_id
            JOIN listing_meeting_location lml ON l.listing_id = lml.listing_id
            JOIN listing_payments lp ON l.listing_id = lp.listing_id
            WHERE lmt.accepted_at IS NOT NULL
            AND lml.accepted_at IS NOT NULL
            AND lp.buyer_paid_at IS NOT NULL
            AND lp.seller_paid_at IS NOT NULL
            LIMIT 1
        """)
        
        listing_data = cursor.fetchone()
        
        if not listing_data:
            print("❌ No completed negotiation with both parties paid found.")
            print("   Need a listing with:")
            print("   - Time agreement (listing_meeting_time.accepted_at IS NOT NULL)")
            print("   - Location agreement (listing_meeting_location.accepted_at IS NOT NULL)")
            print("   - Both parties paid (listing_payments.buyer_paid_at AND seller_paid_at NOT NULL)")
            connection.close()
            return False
        
        listing_id = listing_data['listing_id']
        buyer_id = listing_data['buyer_id']
        seller_id = listing_data['seller_id']
        
        print(f"\n✅ Found test listing: {listing_id}")
        print(f"   Currency: {listing_data['currency']}")
        print(f"   Amount: {listing_data['amount']}")
        print(f"   Buyer: {buyer_id}")
        print(f"   Seller: {seller_id}")
        
        # Create a test session for the buyer
        import uuid
        session_id = str(uuid.uuid4())
        cursor.execute(
            "INSERT INTO usersessions (SessionId, user_id, ExpiresAt) VALUES (%s, %s, DATE_ADD(NOW(), INTERVAL 1 HOUR))",
            (session_id, buyer_id)
        )
        connection.commit()
        
        print(f"\n✅ Created test session: {session_id}")
        
        # Test 1: Complete Exchange
        print("\n" + "-"*60)
        print("TEST 1: CompleteExchange API")
        print("-"*60)
        
        result = json.loads(complete_exchange(session_id, listing_id))
        print(f"Result: {json.dumps(result, indent=2)}")
        
        if result.get('success'):
            print("✅ CompleteExchange succeeded")
            partner_id = result.get('partner_id')
            print(f"   Partner ID: {partner_id}")
            
            # Test 2: Submit Rating
            print("\n" + "-"*60)
            print("TEST 2: SubmitRating API")
            print("-"*60)
            
            if partner_id:
                rating_result = json.loads(submit_rating(
                    SessionId=session_id,
                    user_id=partner_id,
                    Rating=5,
                    Review="Great exchange! Would trade again."
                ))
                print(f"Result: {json.dumps(rating_result, indent=2)}")
                
                if rating_result.get('success'):
                    print("✅ SubmitRating succeeded")
                    
                    # Verify rating was saved
                    cursor.execute("""
                        SELECT rating, review FROM user_ratings 
                        WHERE user_id = %s AND rater_id = %s
                        ORDER BY created_at DESC LIMIT 1
                    """, (partner_id, buyer_id))
                    
                    rating_data = cursor.fetchone()
                    if rating_data:
                        print(f"✅ Rating saved to database: {rating_data['rating']} stars")
                        print(f"   Review: {rating_data['review']}")
                    else:
                        print("❌ Rating not found in database")
                else:
                    print(f"❌ SubmitRating failed: {rating_result.get('error')}")
            else:
                print("❌ No partner_id returned from CompleteExchange")
        else:
            print(f"❌ CompleteExchange failed: {result.get('error')}")
        
        # Cleanup: Remove test session
        cursor.execute("DELETE FROM usersessions WHERE SessionId = %s", (session_id,))
        connection.commit()
        
        print("\n" + "="*60)
        print("TEST COMPLETE")
        print("="*60 + "\n")
        
        return result.get('success', False)
        
    except Exception as e:
        print(f"❌ ERROR: {str(e)}")
        import traceback
        traceback.print_exc()
        return False
    finally:
        connection.close()

if __name__ == "__main__":
    success = test_complete_exchange_flow()
    sys.exit(0 if success else 1)
