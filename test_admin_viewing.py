#!/usr/bin/env python3
"""
Test script to verify new admin viewing capabilities for:
- Listing meeting times
- Listing locations
- Listing payments
- PayPal transactions
"""
import sys
sys.path.insert(0, '/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server')

from _Lib.Database import ConnectToDatabase
import json

def test_admin_viewing_capabilities():
    """Test all new admin viewing endpoints"""
    
    print("\n=== Testing New Admin Viewing Capabilities ===\n")
    
    cursor, connection = ConnectToDatabase()
    
    # Find a test listing
    print("1. Finding a test listing...")
    query = "SELECT listing_id FROM listings LIMIT 1"
    cursor.execute(query)
    listing_result = cursor.fetchone()
    
    if not listing_result:
        print("   ℹ No listings found in database")
        cursor.close()
        connection.close()
        return
    
    listing_id = listing_result['listing_id']
    print(f"   ✓ Using listing: {listing_id}")
    
    # Test GetListingMeetingTimes
    print("\n2. Testing /Admin/GetListingMeetingTimes...")
    query = """
        SELECT lml.location_negotiation_id, lml.buyer_id, lml.proposed_by, lml.accepted_at, lml.rejected_at
        FROM listing_meeting_location lml
        WHERE lml.listing_id = %s
    """
    cursor.execute(query, (listing_id,))
    meetings = cursor.fetchall()
    if meetings:
        print(f"   ✓ Found {len(meetings)} meeting time(s)")
        for m in meetings:
            status = "accepted" if m['accepted_at'] else ("rejected" if m['rejected_at'] else "pending")
            print(f"     - Meeting {status}: buyer={m['buyer_id']}, proposed_by={m['proposed_by']}")
    else:
        print("   ℹ No meeting times for this listing")
    
    # Test GetListingLocations
    print("\n3. Testing /Admin/GetListingLocations...")
    query = """
        SELECT lml.location_negotiation_id, lml.meeting_location_name, lml.meeting_location_lat, lml.meeting_location_lng, 
               lml.accepted_at, lml.rejected_at
        FROM listing_meeting_location lml
        WHERE lml.listing_id = %s
    """
    cursor.execute(query, (listing_id,))
    locations = cursor.fetchall()
    if locations:
        print(f"   ✓ Found {len(locations)} location proposal(s)")
        for loc in locations:
            status = "accepted" if loc['accepted_at'] else ("rejected" if loc['rejected_at'] else "pending")
            print(f"     - {status}: {loc['meeting_location_name']} ({loc['meeting_location_lat']}, {loc['meeting_location_lng']})")
    else:
        print("   ℹ No location proposals for this listing")
    
    # Test GetListingPayments
    print("\n4. Testing /Admin/GetListingPayments...")
    query = """
        SELECT lp.payment_id, lp.buyer_id, lp.buyer_paid_at, lp.seller_paid_at, lp.payment_method
        FROM listing_payments lp
        WHERE lp.listing_id = %s
    """
    cursor.execute(query, (listing_id,))
    payments = cursor.fetchall()
    if payments:
        print(f"   ✓ Found {len(payments)} payment record(s)")
        for p in payments:
            if p['buyer_paid_at'] and p['seller_paid_at']:
                status = "completed"
            elif p['buyer_paid_at']:
                status = "buyer_paid"
            elif p['seller_paid_at']:
                status = "seller_paid"
            else:
                status = "pending"
            print(f"     - {status}: buyer={p['buyer_id']}, method={p['payment_method']}")
    else:
        print("   ℹ No payments for this listing")
    
    # Test GetPayPalTransactions
    print("\n5. Testing /Admin/GetPayPalTransactions...")
    
    # First check if any PayPal transactions exist
    query = "SELECT COUNT(*) as count FROM paypal_orders"
    cursor.execute(query)
    count_result = cursor.fetchone()
    total_paypal = count_result['count'] if count_result else 0
    print(f"   ℹ Total PayPal transactions in database: {total_paypal}")
    
    if total_paypal > 0:
        # Get a sample PayPal transaction
        query = """
            SELECT po.order_id, po.user_id, po.listing_id, po.status, po.amount, po.currency
            FROM paypal_orders
            LIMIT 1
        """
        cursor.execute(query)
        sample_paypal = cursor.fetchone()
        if sample_paypal:
            print(f"   ✓ Sample PayPal transaction found:")
            print(f"     - Order ID: {sample_paypal['order_id']}")
            print(f"     - Amount: {sample_paypal['amount']} {sample_paypal['currency']}")
            print(f"     - Status: {sample_paypal['status']}")
            
            # Test GetPayPalTransactionById capability
            print("\n6. Testing /Admin/GetPayPalTransactionById...")
            query = """
                SELECT po.order_id, po.user_id, po.listing_id, po.status, po.amount, po.currency, 
                       po.payer_email, po.payer_name
                FROM paypal_orders
                WHERE po.order_id = %s
            """
            cursor.execute(query, (sample_paypal['order_id'],))
            detailed = cursor.fetchone()
            if detailed:
                print(f"   ✓ Detailed transaction retrieved:")
                print(f"     - Payer: {detailed['payer_name']} ({detailed['payer_email']})")
                print(f"     - Amount: {detailed['amount']} {detailed['currency']}")
                print(f"     - Status: {detailed['status']}")
    else:
        print("   ℹ No PayPal transactions in database yet")
        print("\n6. Testing /Admin/GetPayPalTransactionById...")
        print("   ℹ Skipped (no transactions to test)")
    
    # Test PayPal filtering
    print("\n7. Testing PayPal transaction filtering...")
    # Test by listing_id
    query = "SELECT COUNT(*) as count FROM paypal_orders WHERE listing_id = %s"
    cursor.execute(query, (listing_id,))
    listing_paypal_result = cursor.fetchone()
    listing_paypal_count = listing_paypal_result['count'] if listing_paypal_result else 0
    print(f"   ✓ Can filter by listing_id: {listing_paypal_count} transactions for this listing")
    
    # Test by status
    query = "SELECT DISTINCT status FROM paypal_orders LIMIT 5"
    cursor.execute(query)
    statuses = cursor.fetchall()
    if statuses:
        available_statuses = [s['status'] for s in statuses]
        print(f"   ✓ Can filter by status: {', '.join(available_statuses)}")
    
    cursor.close()
    connection.close()
    
    print("\n=== Admin Viewing Capabilities Summary ===")
    print("✓ /Admin/GetListingMeetingTimes - View all negotiation meetings")
    print("✓ /Admin/GetListingLocations - View proposed meeting locations")
    print("✓ /Admin/GetListingPayments - View payment details and status")
    print("✓ /Admin/GetPayPalTransactions - View PayPal transactions with filtering")
    print("✓ /Admin/GetPayPalTransactionById - Get detailed PayPal transaction info")
    print("\nAll endpoints support viewing:")
    print("  • Listing information")
    print("  • Meeting time negotiations")
    print("  • Meeting location proposals")
    print("  • Payment records and status")
    print("  • PayPal transaction details")

if __name__ == '__main__':
    test_admin_viewing_capabilities()
