from _Lib import Database
import json
import uuid
from datetime import datetime

def propose_location(negotiation_id, session_id, proposed_location, proposed_latitude=None, proposed_longitude=None, message=None):
    """Propose a location for an agreed meeting time"""
    try:
        print(f"[ProposeLocation] Proposing location for negotiation: {negotiation_id}")
        
        if not negotiation_id or not session_id or not proposed_location:
            return json.dumps({
                'success': False,
                'error': 'Negotiation ID, session ID, and location are required'
            })
        
        # Connect to database
        cursor, connection = Database.ConnectToDatabase()
        
        # Verify session and get user ID
        session_query = """
            SELECT UserId FROM usersessions 
            WHERE SessionId = %s
        """
        cursor.execute(session_query, (session_id,))
        session_result = cursor.fetchone()
        
        if not session_result:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'Invalid or expired session'
            })
        
        proposer_id = session_result['UserId']
        
        # Get negotiation details
        negotiation_query = """
            SELECT buyer_id, seller_id, status
            FROM exchange_negotiations
            WHERE negotiation_id = %s
        """
        cursor.execute(negotiation_query, (negotiation_id,))
        negotiation_result = cursor.fetchone()
        
        if not negotiation_result:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'Negotiation not found'
            })
        
        # Verify user is part of this negotiation
        if proposer_id not in (negotiation_result['buyer_id'], negotiation_result['seller_id']):
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'You are not part of this negotiation'
            })
        
        # Verify negotiation is in 'agreed' status (time was already accepted)
        if negotiation_result['status'] != 'agreed':
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'Meeting time must be agreed upon first'
            })
        
        # Create location proposal history record
        history_id = f"HIS-{str(uuid.uuid4())[:-1]}"
        
        insert_query = """
            INSERT INTO negotiation_history 
            (history_id, negotiation_id, action, proposed_by, proposed_location, 
             proposed_latitude, proposed_longitude, notes)
            VALUES (%s, %s, 'counter_proposal', %s, %s, %s, %s, %s)
        """
        cursor.execute(insert_query, (
            history_id, negotiation_id, proposer_id, 
            proposed_location, proposed_latitude, proposed_longitude, 
            message or ''
        ))
        
        connection.commit()
        connection.close()
        
        print(f"[ProposeLocation] Location proposal created: {history_id}")
        
        return json.dumps({
            'success': True,
            'history_id': history_id,
            'message': 'Location proposal sent successfully'
        })
        
    except Exception as e:
        print(f"[ProposeLocation] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': f'Failed to propose location: {str(e)}'
        })
