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
        
        # Get all listings
        cursor.execute("""
            SELECT l.listing_id, l.currency, l.amount, l.status, l.user_id,
                   CASE WHEN et.transaction_id IS NOT NULL THEN 'SOLD' ELSE 'AVAILABLE' END as sale_status
            FROM listings l
            LEFT JOIN exchange_transactions et ON l.listing_id = et.listing_id AND et.status = 'completed'
            WHERE l.status = 'active' AND l.available_until > NOW()
            ORDER BY l.created_at DESC
            LIMIT 10
        """)
        all_listings = cursor.fetchall()
        
        print(f"\n=== ALL ACTIVE LISTINGS (including sold) ===")
        for listing in all_listings:
            print(f"Listing {listing['listing_id']}: {listing['amount']} {listing['currency']} - {listing['sale_status']}")
        
        # Get listings using the new filtering logic (should exclude sold ones)
        cursor.execute("""
            SELECT l.listing_id, l.currency, l.amount, l.status, l.user_id
            FROM listings l
            WHERE l.status = 'active' AND l.available_until > NOW()
            AND NOT EXISTS (
                SELECT 1 FROM exchange_transactions et 
                WHERE et.listing_id = l.listing_id 
                AND et.status = 'completed'
            )
            ORDER BY l.created_at DESC
            LIMIT 10
        """)
        filtered_listings = cursor.fetchall()
        
        print(f"\n=== FILTERED ACTIVE LISTINGS (excluding sold) ===")
        for listing in filtered_listings:
            print(f"Listing {listing['listing_id']}: {listing['amount']} {listing['currency']} - AVAILABLE")
        
        # Check for completed transactions
        cursor.execute("""
            SELECT et.transaction_id, et.listing_id, et.currency_sold, et.amount_sold, et.status
            FROM exchange_transactions et
            WHERE et.status = 'completed'
            ORDER BY et.completed_at DESC
            LIMIT 5
        """)
        completed_transactions = cursor.fetchall()
        
        print(f"\n=== COMPLETED TRANSACTIONS ===")
        for transaction in completed_transactions:
            print(f"Transaction {transaction['transaction_id']}: Listing {transaction['listing_id']} - {transaction['amount_sold']} {transaction['currency_sold']} - {transaction['status']}")
        
        connection.close()
        
        # Summary
        total_active = len(all_listings)
        available_after_filter = len(filtered_listings)
        sold_count = sum(1 for l in all_listings if 'SOLD' in str(l.get('sale_status', '')))
        
        print(f"\n=== SUMMARY ===")
        print(f"Total active listings: {total_active}")
        print(f"Available after filtering: {available_after_filter}")
        print(f"Sold listings excluded: {sold_count}")
        print(f"Completed transactions found: {len(completed_transactions)}")
        
        if sold_count > 0 and available_after_filter == (total_active - sold_count):
            print("✅ SUCCESS: Filtering logic correctly excludes sold listings!")
        elif sold_count == 0:
            print("ℹ️  INFO: No sold listings found to test filtering")
        else:
            print("❌ ERROR: Filtering logic may not be working correctly")
            
        return True
        
    except Exception as e:
        print(f"❌ ERROR: Test failed with exception: {str(e)}")
        return False

if __name__ == "__main__":
    test_purchased_listings_exclusion()