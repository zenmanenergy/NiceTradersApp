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
        
        # Verify user is not the one who made the current proposal
        if user_id == negotiation['proposed_by']:
            return json.dumps({
                'success': False,
                'error': 'You cannot accept your own proposal'
            })
        
        # Check if negotiation is in correct state
        if negotiation['status'] not in ('proposed', 'countered'):
            return json.dumps({
                'success': False,
                'error': f'Cannot accept proposal in {negotiation["status"]} state'
            })
        
        # Set agreement time and payment deadline (6 hours from now)
        agreement_time = datetime.now()
        payment_deadline = agreement_time + timedelta(hours=6)
        
        # Update negotiation status to 'agreed'
        cursor.execute("""
            UPDATE exchange_negotiations
            SET status = 'agreed',
                agreement_reached_at = %s,
                payment_deadline = %s,
                updated_at = NOW()
            WHERE negotiation_id = %s
        """, (agreement_time, payment_deadline, negotiation_id))
        
        # Log to history (39 chars: HIS- + 35 char UUID)
        history_id = f"HIS-{str(uuid.uuid4())[:-1]}"
        cursor.execute("""
            INSERT INTO negotiation_history (
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
