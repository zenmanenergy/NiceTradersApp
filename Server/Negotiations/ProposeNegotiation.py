import json
import uuid
from datetime import datetime
from _Lib import Database

def propose_negotiation(listing_id, session_id, proposed_time):
    """
    Buyer proposes initial meeting time for a listing
    
    Args:
        listing_id: ID of the listing to negotiate
        session_id: Buyer's session ID
        proposed_time: Proposed meeting time (ISO 8601 format)
    
    Returns:
        JSON response with negotiation details
    """
    cursor, connection = Database.ConnectToDatabase()
    
    try:
        # Verify session and get buyer user_id
        cursor.execute("SELECT UserId FROM usersessions WHERE SessionId = %s", (session_id,))
        session_result = cursor.fetchone()
        
        if not session_result:
            return json.dumps({
                'success': False,
                'error': 'Invalid or expired session'
            })
        
        buyer_id = session_result['UserId']
        
        # Get listing details and verify it exists
        cursor.execute("""
            SELECT user_id, status, available_until
            FROM listings
            WHERE listing_id = %s
        """, (listing_id,))
        
        listing = cursor.fetchone()
        
        if not listing:
            return json.dumps({
                'success': False,
                'error': 'Listing not found'
            })
        
        seller_id = listing['user_id']
        
        # Prevent buyer from negotiating on their own listing
        if buyer_id == seller_id:
            return json.dumps({
                'success': False,
                'error': 'You cannot negotiate on your own listing'
            })
        
        # Check if listing is active
        if listing['status'] != 'active':
            return json.dumps({
                'success': False,
                'error': 'Listing is not active'
            })
        
        # Check if buyer already has an active negotiation for this listing
        cursor.execute("""
            SELECT negotiation_id, status
            FROM exchange_negotiations
            WHERE listing_id = %s
            AND buyer_id = %s
            AND status IN ('proposed', 'countered', 'agreed', 'paid_partial')
        """, (listing_id, buyer_id))
        
        existing_negotiation = cursor.fetchone()
        
        if existing_negotiation:
            return json.dumps({
                'success': False,
                'error': 'You already have an active negotiation for this listing',
                'existingNegotiationId': existing_negotiation['negotiation_id']
            })
        
        # Parse and validate proposed time
        try:
            proposed_datetime = datetime.fromisoformat(proposed_time.replace('Z', '+00:00'))
        except ValueError:
            return json.dumps({
                'success': False,
                'error': 'Invalid date format. Use ISO 8601 format'
            })
        
        # Check if proposed time is in the future
        if proposed_datetime <= datetime.now(proposed_datetime.tzinfo):
            return json.dumps({
                'success': False,
                'error': 'Proposed time must be in the future'
            })
        
        # Create negotiation
        negotiation_id = f"NEG-{uuid.uuid4()}"
        
        cursor.execute("""
            INSERT INTO exchange_negotiations (
                negotiation_id, listing_id, buyer_id, seller_id,
                status, current_proposed_time, proposed_by
            ) VALUES (%s, %s, %s, %s, 'proposed', %s, %s)
        """, (negotiation_id, listing_id, buyer_id, seller_id, proposed_datetime, buyer_id))
        
        # Log to negotiation history
        history_id = f"HIS-{uuid.uuid4()}"
        cursor.execute("""
            INSERT INTO negotiation_history (
                history_id, negotiation_id, action, proposed_time, proposed_by
            ) VALUES (%s, %s, 'initial_proposal', %s, %s)
        """, (history_id, negotiation_id, proposed_datetime, buyer_id))
        
        connection.commit()
        
        return json.dumps({
            'success': True,
            'negotiationId': negotiation_id,
            'status': 'proposed',
            'proposedTime': proposed_time,
            'message': 'Negotiation proposal sent to seller'
        })
        
    except Exception as e:
        connection.rollback()
        print(f"[Negotiations] ProposeNegotiation error: {str(e)}")
        import traceback
        print(f"[Negotiations] Traceback: {traceback.format_exc()}")
        return json.dumps({
            'success': False,
            'error': 'Failed to create negotiation proposal'
        })
    
    finally:
        cursor.close()
        connection.close()
