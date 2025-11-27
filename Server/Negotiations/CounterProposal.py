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
        
        # Get negotiation details
        cursor.execute("""
            SELECT buyer_id, seller_id, status, proposed_by
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
        
        # Check if negotiation is in correct state
        if negotiation['status'] not in ('proposed', 'countered'):
            return json.dumps({
                'success': False,
                'error': f'Cannot counter-propose in {negotiation["status"]} state'
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
        
        # Update negotiation with new proposal
        cursor.execute("""
            UPDATE exchange_negotiations
            SET status = 'countered',
                current_proposed_time = %s,
                proposed_by = %s,
                updated_at = NOW()
            WHERE negotiation_id = %s
        """, (proposed_datetime, user_id, negotiation_id))
        
        # Log to history
        history_id = f"HIS-{uuid.uuid4()}"
        cursor.execute("""
            INSERT INTO negotiation_history (
                history_id, negotiation_id, action, proposed_time, proposed_by
            ) VALUES (%s, %s, 'counter_proposal', %s, %s)
        """, (history_id, negotiation_id, proposed_datetime, user_id))
        
        connection.commit()
        
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
