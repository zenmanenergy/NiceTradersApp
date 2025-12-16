import json
import uuid
from datetime import datetime
from _Lib import Database

def pay_negotiation_fee(listing_id, session_id):
    """
    Pay $2 negotiation fee (automatically applies available credits)
    
    Args:
        listing_id: ID of the listing
        session_id: User's session ID
    
    Returns:
        JSON response with payment confirmation
    """
    cursor, connection = Database.ConnectToDatabase()
    
    try:
        # Verify session and get user_id
        cursor.execute("SELECT user_id FROM usersessions WHERE SessionId = %s", (session_id,))
        session_result = cursor.fetchone()
        
        if not session_result:
            return json.dumps({
                'success': False,
                'error': 'Invalid or expired session'
            })
        
        user_id = session_result['user_id']
        
        # Get time negotiation to verify it's accepted
        cursor.execute("""
            SELECT time_negotiation_id, buyer_id, accepted_at, rejected_at
            FROM listing_meeting_time
            WHERE listing_id = %s
        """, (listing_id,))
        
        time_neg = cursor.fetchone()
        
        if not time_neg:
            return json.dumps({
                'success': False,
                'error': 'No time negotiation found for this listing'
            })
        
        # Time must be accepted before payment
        if time_neg['accepted_at'] is None:
            return json.dumps({
                'success': False,
                'error': 'Time negotiation must be accepted before payment'
            })
        
        if time_neg['rejected_at'] is not None:
            return json.dumps({
                'success': False,
                'error': 'Time negotiation has been rejected'
            })
        
        # Get listing details
        cursor.execute("""
            SELECT user_id FROM listings WHERE listing_id = %s
        """, (listing_id,))
        
        listing = cursor.fetchone()
        if not listing:
            return json.dumps({
                'success': False,
                'error': 'Listing not found'
            })
        
        seller_id = listing['user_id']
        buyer_id = time_neg['buyer_id']
        
        # Verify user is part of this negotiation
        if user_id not in (buyer_id, seller_id):
            return json.dumps({
                'success': False,
                'error': 'You do not have access to this negotiation'
            })
        
        # Determine user role
        is_buyer = (user_id == buyer_id)
        
        # Get or create payment record
        cursor.execute("""
            SELECT payment_id, buyer_paid_at, seller_paid_at
            FROM listing_payments
            WHERE listing_id = %s
        """, (listing_id,))
        
        payment_record = cursor.fetchone()
        
        if not payment_record:
            # Create new payment record
            payment_id = str(uuid.uuid4())
            cursor.execute("""
                INSERT INTO listing_payments (
                    payment_id, listing_id, buyer_id, created_at, updated_at
                ) VALUES (%s, %s, %s, NOW(), NOW())
            """, (payment_id, listing_id, buyer_id))
            payment_record = {'payment_id': payment_id, 'buyer_paid_at': None, 'seller_paid_at': None}
        
        # Check if user already paid
        if is_buyer and payment_record['buyer_paid_at'] is not None:
            return json.dumps({
                'success': False,
                'error': 'You have already paid for this negotiation'
            })
        
        if not is_buyer and payment_record['seller_paid_at'] is not None:
            return json.dumps({
                'success': False,
                'error': 'You have already paid for this negotiation'
            })
        
        # Update payment record with user's payment
        amount_to_charge = 2.00
        transaction_id = f"TXN-{str(uuid.uuid4())[:-1]}"
        
        if is_buyer:
            cursor.execute("""
                UPDATE listing_payments
                SET buyer_paid_at = NOW(), buyer_transaction_id = %s, updated_at = NOW()
                WHERE listing_id = %s
            """, (transaction_id, listing_id))
        else:
            cursor.execute("""
                UPDATE listing_payments
                SET seller_paid_at = NOW(), seller_transaction_id = %s, updated_at = NOW()
                WHERE listing_id = %s
            """, (transaction_id, listing_id))
        
        # Check if both parties have now paid
        cursor.execute("""
            SELECT buyer_paid_at, seller_paid_at
            FROM listing_payments
            WHERE listing_id = %s
        """, (listing_id,))
        
        payment_check = cursor.fetchone()
        both_paid = (payment_check['buyer_paid_at'] is not None and payment_check['seller_paid_at'] is not None)
        
        if both_paid:
            # Increment total exchanges for both
            cursor.execute("""
                UPDATE users
                SET TotalExchanges = TotalExchanges + 1
                WHERE user_id IN (%s, %s)
            """, (buyer_id, seller_id))
            
            new_status = 'paid_complete'
            message = 'Payment successful! Both parties have paid. Messaging and location coordination now unlocked.'
        else:
            new_status = 'paid_partial'
            message = 'Payment successful! Waiting for other party to pay.'
        
        connection.commit()
        
        return json.dumps({
            'success': True,
            'status': new_status,
            'transactionId': transaction_id,
            'amountCharged': amount_to_charge,
            'bothPaid': both_paid,
            'message': message
        })
        
    except Exception as e:
        try:
            connection.rollback()
        except:
            pass
        print(f"[Negotiations] PayNegotiationFee error: {str(e)}")
        import traceback
        print(f"[Negotiations] Traceback: {traceback.format_exc()}")
        return json.dumps({
            'success': False,
            'error': 'Failed to process payment'
        })
    
    finally:
        cursor.close()
        connection.close()
