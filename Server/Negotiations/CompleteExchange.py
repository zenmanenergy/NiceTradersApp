from _Lib import Database
import json
from datetime import datetime

def complete_exchange(SessionId, NegotiationId, CompletionNotes=""):
    """
    Mark an exchange as completed and create exchange history record.
    This happens after both users have met and confirmed the exchange.
    
    Args:
        SessionId: User session ID
        NegotiationId: Negotiation ID to mark as complete
        CompletionNotes: Optional notes about the exchange
    
    Returns: JSON response
    """
    try:
        if not all([SessionId, NegotiationId]):
            return json.dumps({
                'success': False,
                'error': 'Session ID and Negotiation ID are required'
            })
        
        # Connect to database
        cursor, connection = Database.ConnectToDatabase()
        
        # Verify session and get user ID
        session_query = """
            SELECT UserId FROM usersessions 
            WHERE SessionId = %s
        """
        cursor.execute(session_query, (SessionId,))
        session_result = cursor.fetchone()
        
        if not session_result:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'Invalid or expired session'
            })
        
        user_id = session_result['UserId']
        
        # Get negotiation details from history
        cursor.execute("""
            SELECT DISTINCT nh.negotiation_id, nh.listing_id
            FROM negotiation_history nh
            WHERE nh.negotiation_id = %s
            LIMIT 1
        """, (NegotiationId,))
        
        negotiation = cursor.fetchone()
        
        if not negotiation:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'Negotiation not found'
            })
        
        # Get listing and other user info
        cursor.execute("""
            SELECT l.amount, l.currency, l.created_by
            FROM listings l
            WHERE l.ListingId = %s
        """, (negotiation['listing_id'],))
        
        listing = cursor.fetchone()
        if not listing:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'Listing not found'
            })
        
        # Check if both parties have paid by looking for payment records
        cursor.execute("""
            SELECT COUNT(DISTINCT paid_by) as payment_count
            FROM negotiation_history
            WHERE negotiation_id = %s AND paid_by IS NOT NULL
        """, (NegotiationId,))
        
        payment_check = cursor.fetchone()
        if payment_check['payment_count'] < 2:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'Exchange must have both parties paid before completion'
            })
        
        # Determine who the other user is
        seller_id = listing['created_by']
        is_buyer = (user_id != seller_id)
        partner_id = seller_id if is_buyer else user_id  # Get the other person
        
        # Get partner name
        partner_query = "SELECT first_name, last_name FROM users WHERE UserID = %s"
        cursor.execute(partner_query, (partner_id,))
        partner_user = cursor.fetchone()
        partner_name = f"{partner_user['first_name']} {partner_user['last_name']}" if partner_user else "User"
        
        # Determine transaction type
        transaction_type = 'buy' if is_buyer else 'sell'
        
        # Create exchange history record
        import uuid
        exchange_id = str(uuid.uuid4())
        
        history_insert_query = """
            INSERT INTO exchange_history 
            (ExchangeId, UserId, ExchangeDate, Currency, Amount, PartnerName, Rating, Notes, TransactionType, created_at)
            VALUES (%s, %s, NOW(), %s, %s, %s, %s, %s, %s, NOW())
        """
        cursor.execute(history_insert_query, (
            exchange_id,
            user_id,
            listing['currency'],
            float(listing['amount']),
            partner_name,
            0,
            CompletionNotes or f"Exchange completed for {listing['currency']} {listing['amount']}",
            transaction_type
        ))
        
        # Log completion to negotiation history
        history_id = str(uuid.uuid4())
        cursor.execute("""
            INSERT INTO negotiation_history (
                history_id, negotiation_id, action, proposed_by
            ) VALUES (%s, %s, 'completed', %s)
        """, (history_id, NegotiationId, user_id))
        
        
        # Get partner name for notification
        partner_name_query = "SELECT first_name, last_name FROM users WHERE UserID = %s"
        cursor.execute(partner_name_query, (user_id,))
        partner_user = cursor.fetchone()
        partner_display_name = f"{partner_user['first_name']} {partner_user['last_name']}" if partner_user else "User"
        
        # TODO: Send completion notification to partner when notification service is available
        # try:
        #     send_exchange_completed_notification(user_id=partner_id, partner_name=partner_display_name)
        # except Exception as notification_error:
        #     print(f"[CompleteExchange] Warning: Failed to send completion notification")
        
        connection.commit()
        connection.close()
        
        print(f"[CompleteExchange] Successfully completed exchange {NegotiationId}")
        
        return json.dumps({
            'success': True,
            'message': 'Exchange marked as completed',
            'exchange_id': exchange_id
        })
        
    except Exception as e:
        print(f"[CompleteExchange] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': f'Failed to complete exchange: {str(e)}'
        })
