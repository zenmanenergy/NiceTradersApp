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
        
        # Get the most recent proposal to get the proposed_time
        cursor.execute("""
            SELECT proposed_time FROM negotiation_history
            WHERE negotiation_id = %s AND action IN ('time_proposal', 'counter_proposal')
            ORDER BY created_at DESC
            LIMIT 1
        """, (negotiation_id,))
        
        proposal = cursor.fetchone()
        if not proposal or not proposal['proposed_time']:
            return json.dumps({
                'success': False,
                'error': 'No valid proposal found to accept'
            })
        
        proposed_time = proposal['proposed_time']
        
        # Create acceptance record in negotiation_history
        history_id = str(uuid.uuid4())
        agreement_time = datetime.now()
        payment_deadline = agreement_time + timedelta(hours=6)
        
        cursor.execute("""
            INSERT INTO negotiation_history (
                history_id, negotiation_id, listing_id, action, accepted_time, proposed_by, created_at
            ) VALUES (%s, %s, %s, 'accepted_time', %s, %s, NOW())
        """, (history_id, negotiation_id, negotiation['listing_id'], proposed_time, user_id))
        
        connection.commit()
        
        print(f"[Negotiations] AcceptProposal success: negotiation_id={negotiation_id}, user_id={user_id}")
        
        return json.dumps({
            'success': True,
            'status': 'agreed',
            'agreementReachedAt': agreement_time.isoformat(),
            'paymentDeadline': payment_deadline.isoformat(),
            'message': 'Proposal accepted. Both parties must pay within 6 hours.'
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
