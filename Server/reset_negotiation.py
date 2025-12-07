#!/usr/bin/env python3
"""
Reset a negotiation to 'proposed' status for testing.
Clears payment flags, deletes contact_access entries and transaction records.

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
            # Get the specified negotiation
            cursor.execute('''
                SELECT DISTINCT negotiation_id, listing_id
                FROM negotiation_history 
                WHERE negotiation_id = %s
                LIMIT 1
            ''', (negotiation_id,))
        else:
            # Get the most recent paid negotiation
            cursor.execute('''
                SELECT DISTINCT nh.negotiation_id, nh.listing_id
                FROM negotiation_history nh
                WHERE nh.action IN ('buyer_paid', 'seller_paid')
                ORDER BY nh.created_at DESC 
                LIMIT 1
            ''')
        
        neg = cursor.fetchone()
        
        if not neg:
            if negotiation_id:
                print(f'❌ Negotiation {negotiation_id} not found')
            else:
                print('❌ No paid negotiations found')
            return
        
        neg_id = neg['negotiation_id']
        listing_id = neg['listing_id']
        old_status = 'paid'
        
        print(f'Resetting negotiation: {neg_id}')
        print(f'Current status: {old_status}')
        print()
        
        # Get buyer and seller from listing
        cursor.execute('''
            SELECT created_by FROM listings WHERE ListingId = %s
        ''', (listing_id,))
        listing = cursor.fetchone()
        seller_id = listing['created_by'] if listing else None
        
        # Get buyer from first proposal
        cursor.execute('''
            SELECT proposed_by FROM negotiation_history 
            WHERE negotiation_id = %s AND action = 'time_proposal'
            LIMIT 1
        ''', (neg_id,))
        first_proposal = cursor.fetchone()
        buyer_id = first_proposal['proposed_by'] if first_proposal else None
        
        # Delete any transactions related to this negotiation
        cursor.execute('''
            DELETE FROM transactions
            WHERE negotiation_id = %s
        ''', (neg_id,))
        txn_deleted = cursor.rowcount
        
        # Delete the contact_access entries
        if buyer_id and seller_id:
            cursor.execute('''
                DELETE FROM contact_access
                WHERE user_id IN (%s, %s) AND listing_id = %s
            ''', (buyer_id, seller_id, listing_id))
            access_deleted = cursor.rowcount
        else:
            access_deleted = 0
        
        # Delete payment records from negotiation_history
        cursor.execute('''
            DELETE FROM negotiation_history
            WHERE negotiation_id = %s AND action IN ('buyer_paid', 'seller_paid', 'completed')
        ''', (neg_id,))
        
        db.commit()
        
        print(f'✓ Negotiation reset to proposed status')
        print(f'✓ Deleted {access_deleted} contact_access entries')
        print(f'✓ Deleted {txn_deleted} transaction records')
        print()
        print('Next steps:')
        print('1. Go to the negotiation in the app')
        print('2. Accept the proposed meeting time (status → agreed)')
        print('3. Both parties pay the $2 fee')
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
