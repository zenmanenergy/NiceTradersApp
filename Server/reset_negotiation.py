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
                SELECT negotiation_id, listing_id, buyer_id, seller_id, status
                FROM exchange_negotiations 
                WHERE negotiation_id = %s
            ''', (negotiation_id,))
        else:
            # Get the most recent paid/paid_partial negotiation
            cursor.execute('''
                SELECT negotiation_id, listing_id, buyer_id, seller_id, status
                FROM exchange_negotiations 
                WHERE status IN ('paid_complete', 'paid_partial')
                ORDER BY updated_at DESC 
                LIMIT 1
            ''')
        
        neg = cursor.fetchone()
        
        if not neg:
            if negotiation_id:
                print(f'❌ Negotiation {negotiation_id} not found')
            else:
                print('❌ No paid/paid_partial negotiations found')
            return
        
        neg_id = neg['negotiation_id']
        listing_id = neg['listing_id']
        buyer_id = neg['buyer_id']
        seller_id = neg['seller_id']
        old_status = neg['status']
        
        print(f'Resetting negotiation: {neg_id}')
        print(f'Current status: {old_status}')
        print()
        
        # Delete any transactions related to this negotiation
        cursor.execute('''
            DELETE FROM transactions
            WHERE negotiation_id = %s
        ''', (neg_id,))
        txn_deleted = cursor.rowcount
        
        # Delete the contact_access entries
        cursor.execute('''
            DELETE FROM contact_access
            WHERE user_id IN (%s, %s) AND listing_id = %s
        ''', (buyer_id, seller_id, listing_id))
        access_deleted = cursor.rowcount
        
        # Reset the negotiation to proposed status
        cursor.execute('''
            UPDATE exchange_negotiations
            SET status = 'proposed',
                buyer_paid = FALSE,
                seller_paid = FALSE,
                updated_at = NOW()
            WHERE negotiation_id = %s
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
