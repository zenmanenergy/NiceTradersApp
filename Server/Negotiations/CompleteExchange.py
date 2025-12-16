from _Lib import Database
import json
from datetime import datetime
import uuid

def complete_exchange(SessionId, ListingIdOrNegotiationId, CompletionNotes=""):
    """
    Mark an exchange as completed and create exchange history record.
    This happens after both users have met and confirmed the exchange.
    
    Args:
        SessionId: User session ID
        ListingIdOrNegotiationId: Listing ID (using actual schema)
        CompletionNotes: Optional notes about the exchange
    
    Returns: JSON response
    """
    try:
        print(f"[CompleteExchange] Starting: SessionId={SessionId}, ListingIdOrNegotiationId={ListingIdOrNegotiationId}")
        
        if not all([SessionId, ListingIdOrNegotiationId]):
            print(f"[CompleteExchange] Missing required params: SessionId={SessionId}, ListingIdOrNegotiationId={ListingIdOrNegotiationId}")
            return json.dumps({
                'success': False,
                'error': 'Session ID and Listing ID are required'
            })
        
        # Connect to database
        print("[CompleteExchange] Connecting to database...")
        cursor, connection = Database.ConnectToDatabase()
        
        # Verify session and get user ID
        session_query = """
            SELECT user_id FROM usersessions 
            WHERE SessionId = %s
        """
        print(f"[CompleteExchange] Checking session: {SessionId}")
        cursor.execute(session_query, (SessionId,))
        session_result = cursor.fetchone()
        
        print(f"[CompleteExchange] Session result: {session_result}")
        
        if not session_result:
            connection.close()
            print(f"[CompleteExchange] Invalid session: {SessionId}")
            return json.dumps({
                'success': False,
                'error': 'Invalid or expired session'
            })
        
        user_id = session_result['user_id']
        print(f"[CompleteExchange] User ID from session: {user_id}")
        
        # Get listing and determine participants
        listing_id = ListingIdOrNegotiationId
        print(f"[CompleteExchange] Getting listing: {listing_id}")
        cursor.execute("""
            SELECT listing_id, currency, accept_currency, amount, user_id as seller_id
            FROM listings
            WHERE listing_id = %s
        """, (listing_id,))
        
        listing = cursor.fetchone()
        print(f"[CompleteExchange] Listing result: {listing}")
        if not listing:
            connection.close()
            print(f"[CompleteExchange] Listing not found: {listing_id}")
            return json.dumps({
                'success': False,
                'error': 'Listing not found'
            })
        
        # Get time negotiation to get buyer_id
        print("[CompleteExchange] Getting time negotiation...")
        cursor.execute("""
            SELECT time_negotiation_id, buyer_id, accepted_at
            FROM listing_meeting_time
            WHERE listing_id = %s
        """, (listing_id,))
        
        time_neg = cursor.fetchone()
        print(f"[CompleteExchange] Time negotiation result: {time_neg}")
        if not time_neg:
            connection.close()
            print(f"[CompleteExchange] No time negotiation found for listing: {listing_id}")
            return json.dumps({
                'success': False,
                'error': 'No time negotiation found for this listing'
            })
        
        if not time_neg['accepted_at']:
            connection.close()
            print(f"[CompleteExchange] Time not accepted yet for listing: {listing_id}")
            return json.dumps({
                'success': False,
                'error': 'Time has not been agreed upon yet'
            })
        
        # Get location negotiation
        print("[CompleteExchange] Getting location negotiation...")
        cursor.execute("""
            SELECT location_negotiation_id, accepted_at
            FROM listing_meeting_location
            WHERE listing_id = %s
        """, (listing_id,))
        
        location_neg = cursor.fetchone()
        print(f"[CompleteExchange] Location negotiation result: {location_neg}")
        if not location_neg or not location_neg['accepted_at']:
            connection.close()
            print(f"[CompleteExchange] Location not accepted for listing: {listing_id}")
            return json.dumps({
                'success': False,
                'error': 'Location has not been agreed upon yet'
            })
        
        # Check if both parties have paid
        print("[CompleteExchange] Checking payment status...")
        cursor.execute("""
            SELECT payment_id, buyer_paid_at, seller_paid_at
            FROM listing_payments
            WHERE listing_id = %s
        """, (listing_id,))
        
        payment = cursor.fetchone()
        print(f"[CompleteExchange] Payment result: {payment}")
        if not payment or not payment['buyer_paid_at'] or not payment['seller_paid_at']:
            connection.close()
            print(f"[CompleteExchange] Payment not complete for listing: {listing_id}, buyer_paid={payment['buyer_paid_at'] if payment else None}, seller_paid={payment['seller_paid_at'] if payment else None}")
            return json.dumps({
                'success': False,
                'error': 'Exchange must have both parties paid before completion'
            })
        
        # Determine who the other user is
        seller_id = listing['seller_id']
        buyer_id = time_neg['buyer_id']
        is_buyer = (user_id == buyer_id)
        partner_id = seller_id if is_buyer else buyer_id
        
        print(f"[CompleteExchange] User role: seller_id={seller_id}, buyer_id={buyer_id}, current_user={user_id}, is_buyer={is_buyer}, partner_id={partner_id}")
        
        # Get partner name
        partner_query = "SELECT FirstName, LastName FROM users WHERE user_id = %s"
        cursor.execute(partner_query, (partner_id,))
        partner_user = cursor.fetchone()
        partner_name = f"{partner_user['FirstName']} {partner_user['LastName']}" if partner_user else "User"
        
        print(f"[CompleteExchange] Partner name: {partner_name}")
        
        # Mark listing as completed
        print(f"[CompleteExchange] Marking listing as completed: {listing_id}")
        cursor.execute("""
            UPDATE listings
            SET status = 'completed'
            WHERE listing_id = %s
        """, (listing_id,))
        
        connection.commit()
        print(f"[CompleteExchange] Committed to database")
        connection.close()
        
        print(f"[CompleteExchange] Successfully completed exchange for listing {listing_id}")
        
        return json.dumps({
            'success': True,
            'message': 'Exchange marked as completed',
            'listing_id': listing_id,
            'partner_id': partner_id
        })
        
    except Exception as e:
        print(f"[CompleteExchange] Error: {str(e)}")
        import traceback
        traceback.print_exc()
        return json.dumps({
            'success': False,
            'error': f'Failed to complete exchange: {str(e)}'
        })
