import json
import uuid
from datetime import datetime
from _Lib import Database

def counter_proposal(listing_id, session_id, proposed_time):
    """
    Counter-propose a new meeting time
    
    Args:
        listing_id: ID of the listing
        session_id: User's session ID
        proposed_time: New proposed meeting time (ISO 8601 format)
    
    Returns:
        JSON response with updated time negotiation
    """
    cursor, connection = Database.ConnectToDatabase()
    
    try:
        # Verify session and get user_id
        cursor.execute("SELECT user_id FROM user_sessions WHERE session_id = %s", (session_id,))
        session_result = cursor.fetchone()
        
        if not session_result:
            return json.dumps({
                'success': False,
                'error': 'Invalid or expired session'
            })
        
        user_id = session_result['user_id']
        
        # Get time negotiation for this listing
        cursor.execute("""
            SELECT time_negotiation_id, buyer_id, proposed_by FROM listing_meeting_time
            WHERE listing_id = %s
        """, (listing_id,))
        
        time_neg = cursor.fetchone()
        
        if not time_neg:
            return json.dumps({
                'success': False,
                'error': 'No time proposal found for this listing'
            })
        
        # Get listing to find seller_id
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
        
        # Verify user is part of this negotiation (either buyer or seller)
        if user_id != seller_id and user_id != time_neg['buyer_id']:
            return json.dumps({
                'success': False,
                'error': 'You do not have access to this negotiation'
            })
        
        # Cannot counter your own proposal
        if user_id == time_neg['proposed_by']:
            return json.dumps({
                'success': False,
                'error': 'You cannot counter your own proposal'
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
        
        # Update time negotiation with new proposal
        cursor.execute("""
            UPDATE listing_meeting_time
            SET meeting_time = %s, proposed_by = %s, accepted_at = NULL, updated_at = NOW()
            WHERE listing_id = %s
        """, (proposed_datetime, user_id, listing_id))
        
        connection.commit()
        
        print(f"[Negotiations] CounterProposal success: listing_id={listing_id}, user_id={user_id}")
        
        return json.dumps({
            'success': True,
            'status': 'proposed',
            'proposedTime': proposed_time,
            'message': 'Counter-proposal sent'
        })
        
    except Exception as e:
        try:
            connection.rollback()
        except:
            pass
        print(f"[Negotiations] CounterProposal error: {str(e)}")
        import traceback
        print(f"[Negotiations] Traceback: {traceback.format_exc()}")
        return json.dumps({
            'success': False,
            'error': 'Failed to submit counter-proposal'
        })
    
    finally:
        cursor.close()
        connection.close()
