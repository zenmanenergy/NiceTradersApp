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
        
        # Get negotiation details
        negotiation_query = """
            SELECT n.*, l.amount, l.currency, l.accept_currency, u.first_name, u.last_name
            FROM exchange_negotiations n
            JOIN listings l ON n.listing_id = l.listing_id
            JOIN users u ON CASE 
                WHEN n.buyer_id = %s THEN n.seller_id = u.UserID
                ELSE n.buyer_id = u.UserID
            END
            WHERE n.negotiation_id = %s
            AND (n.buyer_id = %s OR n.seller_id = %s)
        """
        cursor.execute(negotiation_query, (user_id, NegotiationId, user_id, user_id))
        negotiation = cursor.fetchone()
        
        if not negotiation:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'Negotiation not found or access denied'
            })
        
        # Only allow completion if negotiation is in paid_complete status
        if negotiation['status'] != 'paid_complete':
            connection.close()
            return json.dumps({
                'success': False,
                'error': f'Exchange must be in paid_complete status to complete. Current status: {negotiation["status"]}'
            })
        
        # Determine transaction type (buyer or seller perspective)
        is_buyer = negotiation['buyer_id'] == user_id
        transaction_type = 'buy' if is_buyer else 'sell'
        partner_id = negotiation['seller_id'] if is_buyer else negotiation['buyer_id']
        partner_name = f"{negotiation['first_name']} {negotiation['last_name']}"
        
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
            negotiation['currency'],
            float(negotiation['amount']),
            partner_name,
            0,  # Rating will be 0 initially, updated when user rates
            CompletionNotes or f"Exchange completed for {negotiation['currency']} {negotiation['amount']}",
            transaction_type
        ))
        
        # Update negotiation status to 'completed'
        update_negotiation_query = """
            UPDATE exchange_negotiations
            SET status = 'completed', updated_at = NOW()
            WHERE negotiation_id = %s
        """
        cursor.execute(update_negotiation_query, (NegotiationId,))
        
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
