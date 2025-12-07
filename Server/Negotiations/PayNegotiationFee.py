import json
import uuid
from datetime import datetime
from _Lib import Database

def pay_negotiation_fee(negotiation_id, session_id):
    """
    Pay $2 negotiation fee (automatically applies available credits)
    
    Args:
        negotiation_id: ID of the negotiation
        session_id: User's session ID
    
    Returns:
        JSON response with payment confirmation
    """
    cursor, connection = Database.ConnectToDatabase()
    
    try:
        # Verify session and get user_id
        cursor.execute("SELECT UserId FROM usersessions WHERE SessionId = %s", (session_id,))
        session_result = cursor.fetchone()
        
        if not session_result:
            return json.dumps({
                'success': False,
                'error': 'Invalid or expired session'
            })
        
        user_id = session_result['UserId']
        
        # Get negotiation details from history - get latest state
        cursor.execute("""
            SELECT DISTINCT
                nh.negotiation_id,
                nh.listing_id,
                (SELECT proposed_by FROM negotiation_history WHERE negotiation_id = %s AND action IN ('time_proposal') LIMIT 1) as initiator_id
            FROM negotiation_history nh
            WHERE nh.negotiation_id = %s
        """, (negotiation_id, negotiation_id))
        
        negotiation = cursor.fetchone()
        
        if not negotiation:
            return json.dumps({
                'success': False,
                'error': 'Negotiation not found'
            })
        
        # Get buyer/seller from listing
        cursor.execute("""
            SELECT created_by, ListingId FROM listings WHERE ListingId = %s
        """, (negotiation['listing_id'],))
        
        listing = cursor.fetchone()
        if not listing:
            return json.dumps({
                'success': False,
                'error': 'Listing not found'
            })
        
        seller_id = listing['created_by']
        buyer_id = negotiation['initiator_id']
        
        # Verify user is part of this negotiation
        if user_id not in (buyer_id, seller_id):
            return json.dumps({
                'success': False,
                'error': 'You do not have access to this negotiation'
            })
        
        # Determine user role
        is_buyer = (user_id == buyer_id)
        
        # Check if user already paid by looking for payment records
        cursor.execute("""
            SELECT COUNT(*) as payment_count FROM transactions
            WHERE negotiation_id = %s AND user_id = %s AND status = 'completed'
        """, (negotiation_id, user_id))
        
        payment_check = cursor.fetchone()
        if payment_check['payment_count'] > 0:
            return json.dumps({
                'success': False,
                'error': 'You have already paid for this negotiation'
            })
        
        # Check if there's an accepted meeting (both parties agreed)
        cursor.execute("""
            SELECT COUNT(*) as accepted_count FROM negotiation_history
            WHERE negotiation_id = %s AND action IN ('accepted_time', 'accepted_location')
        """, (negotiation_id,))
        
        accepted_check = cursor.fetchone()
        if accepted_check['accepted_count'] == 0:
            return json.dumps({
                'success': False,
                'error': 'Cannot pay for negotiation that hasn\'t been accepted by both parties'
            })
        
        # Check for available credits
        cursor.execute("""
            SELECT credit_id, amount
            FROM user_credits
            WHERE user_id = %s
            AND status = 'available'
            AND (expires_at IS NULL OR expires_at > NOW())
            ORDER BY created_at ASC
            LIMIT 1
        """, (user_id,))
        
        credit = cursor.fetchone()
        
        amount_to_charge = 2.00
        credit_used = 0.00
        credit_id_used = None
        
        if credit:
            # Apply credit
            credit_amount = float(credit['amount'])
            if credit_amount >= amount_to_charge:
                # Credit covers full amount
                credit_used = amount_to_charge
                amount_to_charge = 0.00
                credit_id_used = credit['credit_id']
                
                # Mark credit as applied
                cursor.execute("""
                    UPDATE user_credits
                    SET status = 'applied',
                        applied_to_negotiation_id = %s,
                        applied_at = NOW()
                    WHERE credit_id = %s
                """, (negotiation_id, credit_id_used))
        
        # Create transaction record (39 chars: TXN- + 35 char UUID)
        transaction_id = f"TXN-{str(uuid.uuid4())[:-1]}"
        cursor.execute("""
            INSERT INTO transactions (
                transaction_id, user_id, listing_id, negotiation_id,
                amount, currency, transaction_type, status,
                payment_method, description, completed_at
            ) VALUES (%s, %s, %s, %s, %s, 'USD', 'contact_fee', 'completed', %s, %s, NOW())
        """, (
            transaction_id,
            user_id,
            negotiation['listing_id'],
            negotiation_id,
            amount_to_charge,
            'credit' if credit_used > 0 else 'default',
            f"Negotiation fee - ${credit_used:.2f} credit applied" if credit_used > 0 else "Negotiation fee payment"
        ))
        
        # Update negotiation payment status in history
        payment_action = 'buyer_paid' if is_buyer else 'seller_paid'
        cursor.execute("""
            INSERT INTO negotiation_history (
                history_id, negotiation_id, action, proposed_by, paid_by
            ) VALUES (%s, %s, %s, %s, %s)
        """, (str(uuid.uuid4()), negotiation_id, payment_action, user_id, user_id))
        
        # Check if both parties have now paid
        cursor.execute("""
            SELECT COUNT(DISTINCT paid_by) as paying_users FROM negotiation_history
            WHERE negotiation_id = %s AND paid_by IN (%s, %s)
        """, (negotiation_id, buyer_id, seller_id))
        
        payment_count = cursor.fetchone()
        both_paid = (payment_count['paying_users'] == 2)
        
        if both_paid:
            # Both paid - auto-reject other negotiations for this listing
            cursor.execute("""
                UPDATE negotiation_history
                SET action = 'rejected'
                WHERE listing_id = %s
                AND negotiation_id != %s
                AND action IN ('time_proposal', 'location_proposal', 'counter_proposal')
                AND (SELECT COUNT(*) FROM negotiation_history nh2 
                     WHERE nh2.negotiation_id = negotiation_history.negotiation_id 
                     AND nh2.action IN ('accepted_time', 'accepted_location')) = 0
            """, (negotiation['listing_id'], negotiation_id))
            
            # Create contact_access entries for both buyer and seller
            buyer_access_id = f"CAC-{str(uuid.uuid4())[:-1]}"
            seller_access_id = f"CAC-{str(uuid.uuid4())[:-1]}"
            
            # Buyer gets access to listing
            cursor.execute("""
                INSERT INTO contact_access (
                    access_id, user_id, listing_id, purchased_at, 
                    status, amount_paid, currency
                ) VALUES (%s, %s, %s, NOW(), 'active', %s, 'USD')
            """, (buyer_access_id, buyer_id, negotiation['listing_id'], amount_to_charge))
            
            # Seller gets access to listing  
            cursor.execute("""
                INSERT INTO contact_access (
                    access_id, user_id, listing_id, purchased_at,
                    status, amount_paid, currency
                ) VALUES (%s, %s, %s, NOW(), 'active', %s, 'USD')
            """, (seller_access_id, seller_id, negotiation['listing_id'], amount_to_charge))
            
            # Increment total exchanges for both buyer and seller
            cursor.execute("""
                UPDATE users
                SET TotalExchanges = TotalExchanges + 1
                WHERE UserID IN (%s, %s)
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
            'creditApplied': credit_used,
            'bothPaid': both_paid,
            'message': message
        })
        
    except Exception as e:
        connection.rollback()
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
