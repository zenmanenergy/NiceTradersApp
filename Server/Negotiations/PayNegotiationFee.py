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
        
        # Get negotiation details
        cursor.execute("""
            SELECT 
                buyer_id, seller_id, listing_id, status,
                buyer_paid, seller_paid,
                buyer_payment_transaction_id, seller_payment_transaction_id,
                payment_deadline
            FROM exchange_negotiations
            WHERE negotiation_id = %s
        """, (negotiation_id,))
        
        negotiation = cursor.fetchone()
        
        if not negotiation:
            return json.dumps({
                'success': False,
                'error': 'Negotiation not found'
            })
        
        # Verify user is part of this negotiation
        if user_id not in (negotiation['buyer_id'], negotiation['seller_id']):
            return json.dumps({
                'success': False,
                'error': 'You do not have access to this negotiation'
            })
        
        # Determine user role
        is_buyer = (user_id == negotiation['buyer_id'])
        
        # Check if negotiation is in agreed state
        if negotiation['status'] not in ('agreed', 'paid_partial'):
            return json.dumps({
                'success': False,
                'error': f'Cannot pay for negotiation in {negotiation["status"]} state'
            })
        
        # Check if user already paid
        if (is_buyer and negotiation['buyer_paid']) or (not is_buyer and negotiation['seller_paid']):
            return json.dumps({
                'success': False,
                'error': 'You have already paid for this negotiation'
            })
        
        # Check if payment deadline has passed
        if negotiation['payment_deadline'] and datetime.now() > negotiation['payment_deadline']:
            # Mark as expired
            cursor.execute("""
                UPDATE exchange_negotiations
                SET status = 'expired'
                WHERE negotiation_id = %s
            """, (negotiation_id,))
            connection.commit()
            
            return json.dumps({
                'success': False,
                'error': 'Payment deadline has passed. Negotiation expired.'
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
        
        # Update negotiation payment status
        if is_buyer:
            cursor.execute("""
                UPDATE exchange_negotiations
                SET buyer_paid = 1,
                    buyer_paid_at = NOW(),
                    buyer_payment_transaction_id = %s,
                    updated_at = NOW()
                WHERE negotiation_id = %s
            """, (transaction_id, negotiation_id))
        else:
            cursor.execute("""
                UPDATE exchange_negotiations
                SET seller_paid = 1,
                    seller_paid_at = NOW(),
                    seller_payment_transaction_id = %s,
                    updated_at = NOW()
                WHERE negotiation_id = %s
            """, (transaction_id, negotiation_id))
        
        # Check if both parties have now paid
        cursor.execute("""
            SELECT buyer_paid, seller_paid
            FROM exchange_negotiations
            WHERE negotiation_id = %s
        """, (negotiation_id,))
        
        updated_negotiation = cursor.fetchone()
        both_paid = updated_negotiation['buyer_paid'] and updated_negotiation['seller_paid']
        
        if both_paid:
            # Both paid - mark as paid_complete and auto-reject other negotiations
            cursor.execute("""
                UPDATE exchange_negotiations
                SET status = 'paid_complete'
                WHERE negotiation_id = %s
            """, (negotiation_id,))
            
            # Auto-reject all other negotiations for this listing
            cursor.execute("""
                UPDATE exchange_negotiations
                SET status = 'rejected',
                    updated_at = NOW()
                WHERE listing_id = %s
                AND negotiation_id != %s
                AND status IN ('proposed', 'countered', 'agreed', 'paid_partial')
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
            """, (buyer_access_id, negotiation['buyer_id'], negotiation['listing_id'], amount_to_charge))
            
            # Seller gets access to listing  
            cursor.execute("""
                INSERT INTO contact_access (
                    access_id, user_id, listing_id, purchased_at,
                    status, amount_paid, currency
                ) VALUES (%s, %s, %s, NOW(), 'active', %s, 'USD')
            """, (seller_access_id, negotiation['seller_id'], negotiation['listing_id'], amount_to_charge))
            
            new_status = 'paid_complete'
            message = 'Payment successful! Both parties have paid. Messaging and location coordination now unlocked.'
        else:
            # Only this user paid so far
            cursor.execute("""
                UPDATE exchange_negotiations
                SET status = 'paid_partial'
                WHERE negotiation_id = %s
            """, (negotiation_id,))
            
            new_status = 'paid_partial'
            message = 'Payment successful! Waiting for other party to pay.'
        
        # Log to history (39 chars: HIS- + 35 char UUID)
        history_id = f"HIS-{str(uuid.uuid4())[:-1]}"
        action = 'buyer_paid' if is_buyer else 'seller_paid'
        cursor.execute("""
            INSERT INTO negotiation_history (
                history_id, negotiation_id, action, proposed_by
            ) VALUES (%s, %s, %s, %s)
        """, (history_id, negotiation_id, action, user_id))
        
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
