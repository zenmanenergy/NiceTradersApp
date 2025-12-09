import json
import uuid
from datetime import datetime
from _Lib import Database

def counter_proposal(negotiation_id, session_id, proposed_time):
    """
    Counter-propose a new meeting time
    
    Args:
        negotiation_id: ID of the negotiation
        session_id: User's session ID
        proposed_time: New proposed meeting time (ISO 8601 format)
    
    Returns:
        JSON response with updated negotiation
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
        
        # Get negotiation details from history
        cursor.execute("""
            SELECT DISTINCT negotiation_id, listing_id FROM negotiation_history
            WHERE negotiation_id = %s
            LIMIT 1
        """, (negotiation_id,))
        
        negotiation = cursor.fetchone()
        
        if not negotiation:
            return json.dumps({
                'success': False,
                'error': 'Negotiation not found'
            })
        
        # Get listing info to determine buyer/seller
        cursor.execute("""
            SELECT user_id FROM listings WHERE listing_id = %s
        """, (negotiation['listing_id'],))
        
        listing = cursor.fetchone()
        if not listing:
            return json.dumps({
                'success': False,
                'error': 'Listing not found'
            })
        
        seller_id = listing['user_id']
        
        # Get latest proposal to check state
        cursor.execute("""
            SELECT proposed_by FROM negotiation_history
            WHERE negotiation_id = %s
            ORDER BY created_at DESC
            LIMIT 1
        """, (negotiation_id,))
        
        last_proposal = cursor.fetchone()
        if not last_proposal:
            return json.dumps({
                'success': False,
                'error': 'No proposals found for this negotiation'
            })
        
        # Verify user is part of this negotiation and didn't make last proposal
        cursor.execute("""
            SELECT DISTINCT proposed_by FROM negotiation_history
            WHERE negotiation_id = %s
        """, (negotiation_id,))
        
        participants = cursor.fetchall()
        participant_ids = [p['proposed_by'] for p in participants]
        
        if user_id not in participant_ids:
            return json.dumps({
                'success': False,
                'error': 'You do not have access to this negotiation'
            })
        
        if user_id == last_proposal['proposed_by']:
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
        
        # Log counter-proposal to history
        history_id = str(uuid.uuid4())
        cursor.execute("""
            INSERT INTO negotiation_history (
                history_id, negotiation_id, listing_id, action, proposed_time, proposed_by, created_at
            ) VALUES (%s, %s, %s, 'counter_proposal', %s, %s, NOW())
        """, (history_id, negotiation_id, negotiation['listing_id'], proposed_datetime, user_id))
        
        connection.commit()
        
        print(f"[Negotiations] CounterProposal success: negotiation_id={negotiation_id}, user_id={user_id}")
        
        return json.dumps({
            'success': True,
            'status': 'countered',
            'proposedTime': proposed_time,
            'message': 'Counter-proposal sent'
        })
        
    except Exception as e:
        connection.rollback()
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
