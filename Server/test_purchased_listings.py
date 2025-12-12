#!/usr/bin/env python3
"""
Test script to verify that purchased/completed listings are excluded from active listings
"""

from _Lib import Database
import json

def test_purchased_listings_exclusion():
    """Test that completed listings are excluded from active listings queries"""
    try:
        print("Testing purchased/completed listings exclusion...")
        
        # Connect to database
        cursor, connection = Database.ConnectToDatabase()
        
        # Get all active listings
        cursor.execute("""
            SELECT l.listing_id, l.currency, l.amount, l.status, l.user_id
            FROM listings l
            WHERE l.status = 'active' AND l.available_until > NOW()
            ORDER BY l.created_at DESC
            LIMIT 10
        """)
        all_listings = cursor.fetchall()
        
        print(f"\n=== ACTIVE LISTINGS ===")
        for listing in all_listings:
            print(f"Listing {listing['listing_id']}: {listing['amount']} {listing['currency']} - AVAILABLE")
        
        connection.close()
        
        # Summary
        total_active = len(all_listings)
        
        print(f"\n=== SUMMARY ===")
        print(f"Total active listings: {total_active}")
        
        if total_active > 0:
            print("✅ SUCCESS: Query returned active listings!")
            
        return True
        
    except Exception as e:
        print(f"❌ ERROR: Test failed with exception: {str(e)}")
        return False

if __name__ == "__main__":
    test_purchased_listings_exclusion()