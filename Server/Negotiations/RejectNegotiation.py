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
        
        # Get negotiation details
        cursor.execute("""
            SELECT buyer_id, seller_id, status
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
        
        # Check if negotiation can be rejected
        if negotiation['status'] in ('rejected', 'cancelled', 'expired', 'paid_complete'):
            return json.dumps({
                'success': False,
                'error': f'Cannot reject negotiation in {negotiation["status"]} state'
            })
        
        # Update negotiation status to 'rejected'
        cursor.execute("""
            UPDATE exchange_negotiations
            SET status = 'rejected',
                updated_at = NOW()
            WHERE negotiation_id = %s
        """, (negotiation_id,))
        
        # Log to history (39 chars: HIS- + 35 char UUID)
        history_id = f"HIS-{str(uuid.uuid4())[:-1]}"
        cursor.execute("""
            INSERT INTO negotiation_history (
                history_id, negotiation_id, action, proposed_by
            ) VALUES (%s, %s, 'rejected', %s)
        """, (history_id, negotiation_id, user_id))
        
        connection.commit()
        
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
