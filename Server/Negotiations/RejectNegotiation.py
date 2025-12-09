import json
import uuid
from _Lib import Database

def reject_negotiation(negotiation_id, session_id):
    """
    Reject negotiation outright (ends the negotiation)
    
    Args:
        negotiation_id: ID of the negotiation
        session_id: User's session ID
    
    Returns:
        JSON response confirming rejection
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
        
        # Get all participants
        cursor.execute("""
            SELECT DISTINCT proposed_by FROM negotiation_history
            WHERE negotiation_id = %s
        """, (negotiation_id,))
        
        participants = cursor.fetchall()
        participant_ids = [p['proposed_by'] for p in participants]
        
        # Verify user is part of this negotiation
        if user_id not in participant_ids:
            return json.dumps({
                'success': False,
                'error': 'You do not have access to this negotiation'
            })
        
        # Check if already rejected or completed
        cursor.execute("""
            SELECT action FROM negotiation_history
            WHERE negotiation_id = %s
            ORDER BY created_at DESC
            LIMIT 1
        """, (negotiation_id,))
        
        last_action = cursor.fetchone()
        if last_action and last_action['action'] in ('rejected', 'paid_complete'):
            return json.dumps({
                'success': False,
                'error': f'Cannot reject negotiation in {last_action["action"]} state'
            })
        
        # Log rejection to history
        history_id = str(uuid.uuid4())
        cursor.execute("""
            INSERT INTO negotiation_history (
                history_id, negotiation_id, listing_id, action, proposed_by, created_at
            ) VALUES (%s, %s, %s, 'rejected', %s, NOW())
        """, (history_id, negotiation_id, negotiation['listing_id'], user_id))
        
        connection.commit()
        
        print(f"[Negotiations] RejectNegotiation success: negotiation_id={negotiation_id}, user_id={user_id}")
        
        return json.dumps({
            'success': True,
            'status': 'rejected',
            'message': 'Negotiation rejected'
        })
        
    except Exception as e:
        connection.rollback()
        print(f"[Negotiations] RejectNegotiation error: {str(e)}")
        import traceback
        print(f"[Negotiations] Traceback: {traceback.format_exc()}")
        return json.dumps({
            'success': False,
            'error': 'Failed to reject negotiation'
        })
    
    finally:
        cursor.close()
        connection.close()
