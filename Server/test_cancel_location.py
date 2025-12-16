#!/usr/bin/env python3
"""
Unit test for CancelLocation functionality
Tests that the cancel location endpoint properly deletes meeting location proposals
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from Meeting.CancelLocation import cancel_location
from _Lib.Database import ConnectToDatabase

def test_cancel_location():
    """Test cancel_location function"""
    print("\n=== Testing CancelLocation ===\n")
    
    # Get database connection to set up test data
    cursor, db = ConnectToDatabase()
    
    try:
        # First, let's check what listings exist
        cursor.execute("SELECT listing_id, user_id, buyer_id FROM listings LIMIT 1")
        listing = cursor.fetchone()
        
        if not listing:
            print("❌ No listings found in database")
            return
        
        listing_id = listing['listing_id']
        seller_id = listing['user_id']
        
        print(f"✅ Found test listing: {listing_id}")
        print(f"   Seller ID: {seller_id}")
        
        # Get a valid session for the seller
        cursor.execute("""
            SELECT SessionId FROM usersessions 
            WHERE user_id = %s 
            LIMIT 1
        """, (seller_id,))
        session_result = cursor.fetchone()
        
        if not session_result:
            print("❌ No session found for seller")
            return
        
        session_id = session_result['SessionId']
        print(f"✅ Found session: {session_id}")
        
        # Check if location exists
        cursor.execute("""
            SELECT * FROM listing_meeting_location 
            WHERE listing_id = %s
        """, (listing_id,))
        location_before = cursor.fetchone()
        
        if location_before:
            print(f"✅ Found existing location proposal to delete")
        else:
            print("⚠️  No location proposal exists for this listing")
        
        # Call cancel_location
        print(f"\n📍 Calling cancel_location({session_id}, {listing_id})...")
        result = cancel_location(session_id, listing_id)
        
        print(f"Result: {result}")
        
        if result['success']:
            print("✅ Cancel location returned success")
            
            # Close and reopen connection to see the committed changes
            cursor.close()
            db.close()
            
            # Get fresh connection
            cursor, db = ConnectToDatabase()
            
            # Verify the location was deleted
            cursor.execute("""
                SELECT * FROM listing_meeting_location 
                WHERE listing_id = %s
            """, (listing_id,))
            location_after = cursor.fetchone()
            
            if location_after:
                print("❌ Location still exists after cancel!")
            else:
                print("✅ Location successfully deleted from database")
        else:
            print(f"❌ Cancel location failed: {result['message']}")
    
    finally:
        cursor.close()
        db.close()
        print("\n=== Test Complete ===\n")

if __name__ == "__main__":
    test_cancel_location()
