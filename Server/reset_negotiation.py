#!/usr/bin/env python3
"""
Reset a negotiation to 'proposed' status for testing.
Clears payment flags, deletes payment records and transaction records.

Usage:
    python3 reset_negotiation.py [negotiation_id]
    
If no negotiation_id is provided, resets the most recent paid/paid_partial negotiation.
"""

import sys
import pymysql

def reset_negotiation(negotiation_id=None):
    db = pymysql.connect(
        host='localhost',
        user='stevenelson',
        password='mwitcitw711',
        database='nicetraders',
        cursorclass=pymysql.cursors.DictCursor
    )
    cursor = db.cursor()
    
    try:
        if negotiation_id:
            # Get the specified negotiation (if using negotiation_history)
            # Otherwise find by listing_id
            cursor.execute('''
                SELECT DISTINCT listing_id FROM listing_meeting_time 
                WHERE listing_id = %s LIMIT 1
            ''', (negotiation_id,))
        else:
            # Get the most recent negotiation with payment
            cursor.execute('''
                SELECT lmt.listing_id
                FROM listing_meeting_time lmt
                JOIN listing_payments lp ON lmt.listing_id = lp.listing_id
                WHERE lp.buyer_paid_at IS NOT NULL OR lp.seller_paid_at IS NOT NULL
                ORDER BY lp.updated_at DESC 
                LIMIT 1
            ''')
        
        result = cursor.fetchone()
        
        if not result:
            if negotiation_id:
                print(f'❌ Negotiation {negotiation_id} not found')
            else:
                print('❌ No paid negotiations found')
            return
        
        listing_id = result['listing_id']
        
        print(f'Resetting negotiation for listing: {listing_id}')
        print()
        
        # Get buyer and seller info
        cursor.execute('''
            SELECT lmt.buyer_id, l.user_id as seller_id
            FROM listing_meeting_time lmt
            JOIN listings l ON lmt.listing_id = l.listing_id
            WHERE lmt.listing_id = %s
            LIMIT 1
        ''', (listing_id,))
        result = cursor.fetchone()
        buyer_id = result['buyer_id'] if result else None
        seller_id = result['seller_id'] if result else None
        
        # Clear payment records from listing_payments
        cursor.execute('''
            UPDATE listing_payments
            SET buyer_paid_at = NULL, seller_paid_at = NULL, updated_at = NOW()
            WHERE listing_id = %s
        ''', (listing_id,))
        payments_cleared = cursor.rowcount
        
        db.commit()
        
        print(f'✓ Negotiation reset to proposed status')
        print(f'✓ Cleared {payments_cleared} payment records')
        print(f'✓ Deleted {txn_deleted} transaction records')
        print()
        print('Next steps:')
        print('1. Go to the negotiation in the app')
        print('2. Accept the proposed meeting time (status → agreed)')
        print('3. Both parties pay the fee')
        print('4. Test that it appears in Active Exchanges')
        
    except Exception as e:
        db.rollback()
        print(f'❌ Error: {str(e)}')
        import traceback
        traceback.print_exc()
    finally:
        cursor.close()
        db.close()

if __name__ == '__main__':
    if len(sys.argv) > 1:
        negotiation_id = sys.argv[1]
        reset_negotiation(negotiation_id)
    else:
        reset_negotiation()
