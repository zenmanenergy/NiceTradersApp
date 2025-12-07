import json
import uuid
from datetime import datetime, timedelta
from _Lib import Database

def accept_proposal(negotiation_id, session_id):
    """
    Accept the current proposal and set 2-hour payment deadline
    
    Args:
        negotiation_id: ID of the negotiation
        session_id: User's session ID
    
    Returns:
        JSON response with updated negotiation status
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
        
        # Get negotiation details from negotiation_history
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
        
        # Create acceptance record in negotiation_history
        history_id = str(uuid.uuid4())
        cursor.execute("""
            INSERT INTO negotiation_history (
                history_id, negotiation_id, listing_id, action, proposed_by, created_at
            ) VALUES (%s, %s, %s, 'accepted_time', %s, NOW())
        """, (history_id, negotiation_id, negotiation['listing_id'], user_id))
                history_id, negotiation_id, action, proposed_by
            ) VALUES (%s, %s, 'accepted', %s)
        """, (history_id, negotiation_id, user_id))
        
        connection.commit()
        
        return json.dumps({
            'success': True,
            'status': 'agreed',
            'agreementReachedAt': agreement_time.isoformat(),
            'paymentDeadline': payment_deadline.isoformat(),
            'message': 'Proposal accepted. Both parties must pay $2 within 6 hours.'
        })
        
    except Exception as e:
        connection.rollback()
        print(f"[Negotiations] AcceptProposal error: {str(e)}")
        import traceback
        print(f"[Negotiations] Traceback: {traceback.format_exc()}")
        return json.dumps({
            'success': False,
            'error': 'Failed to accept proposal'
        })
    
    finally:
        cursor.close()
        connection.close()
