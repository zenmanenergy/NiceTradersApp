from _Lib import Database
import json
import uuid
from datetime import datetime, timezone

def respond_to_meeting(session_id, proposal_id, response):
    """Accept or reject a meeting proposal stored in negotiation_history"""
    try:
        print(f"[RespondToMeeting] Responding to proposal: {proposal_id} with: {response}")
        
        if not session_id or not proposal_id or response not in ['accepted', 'rejected']:
            return json.dumps({
                'success': False,
                'error': 'Session ID, proposal ID, and valid response (accepted/rejected) are required'
            })
        
        # Connect to database
        cursor, connection = Database.ConnectToDatabase()
        
        # Verify session and get user ID
        session_query = """
            SELECT user_id FROM usersessions 
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
        
        user_id = session_result['user_id']
        
        # Get proposal details from negotiation_history only
        proposal_query = """
            SELECT nh.history_id, nh.negotiation_id, nh.proposed_location, nh.proposed_time, 
                   nh.proposed_latitude, nh.proposed_longitude, nh.notes, nh.proposed_by,
                   nh.listing_id,
                   u.FirstName, u.LastName
            FROM negotiation_history nh
            JOIN users u ON nh.proposed_by = u.user_id
            WHERE nh.history_id = %s
        """
        cursor.execute(proposal_query, (proposal_id,))
        proposal_result = cursor.fetchone()
        
        if not proposal_result:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'Meeting proposal not found'
            })
        
        # Verify user is not the proposer (can't accept own proposal)
        if proposal_result['proposed_by'] == user_id:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'You cannot respond to your own proposal'
            })
        
        # Create acceptance/rejection record in negotiation_history
        # For 'accepted' action, copy the proposed values to accepted_* columns
        response_history_id = str(uuid.uuid4())
        response_query = """
            INSERT INTO negotiation_history 
            (history_id, negotiation_id, action, proposed_time, proposed_location,
             proposed_latitude, proposed_longitude, accepted_time, accepted_location,
             accepted_latitude, accepted_longitude, proposed_by, notes, created_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, NOW())
        """
        
        # If accepting, copy proposed values to accepted columns; if rejecting, leave NULL
        accepted_time = proposal_result['proposed_time'] if response == 'accepted' else None
        accepted_location = proposal_result['proposed_location'] if response == 'accepted' else None
        accepted_latitude = proposal_result['proposed_latitude'] if response == 'accepted' else None
        accepted_longitude = proposal_result['proposed_longitude'] if response == 'accepted' else None
        
        # Use 'accepted_time' for time proposals, 'accepted_location' for location-only proposals
        action = response
        if response == 'accepted':
            # Determine if this is a time acceptance or location acceptance
            if accepted_time is not None:
                action = 'accepted_time'
            elif accepted_location is not None:
                action = 'accepted_location'
        
        cursor.execute(response_query, (
            response_history_id,
            proposal_result['negotiation_id'],
            action,
            proposal_result['proposed_time'],
            proposal_result['proposed_location'],
            proposal_result['proposed_latitude'],
            proposal_result['proposed_longitude'],
            accepted_time,
            accepted_location,
            accepted_latitude,
            accepted_longitude,
            user_id,  # responder
            f"Responded: {response}"
        ))
        
        connection.commit()
        connection.close()
        
        print(f"[RespondToMeeting] Proposal {proposal_id} {response} successfully")
        
        # Format proposed_time with timezone
        proposed_time = proposal_result['proposed_time']
        if proposed_time and proposed_time.tzinfo is None:
            proposed_time = proposed_time.replace(tzinfo=timezone.utc)
        
        return json.dumps({
            'success': True,
            'message': f'Meeting proposal {response} successfully',
            'proposal': {
                'proposal_id': proposal_result['history_id'],
                'listing_id': proposal_result['final_listing_id'],
                'proposed_location': proposal_result['proposed_location'],
                'proposed_time': proposed_time.isoformat() if proposed_time else None,
                'message': proposal_result['notes'],
                'status': response,
                'proposer': {
                    'first_name': proposal_result['FirstName'],
                    'last_name': proposal_result['LastName']
                }
            }
        })
        
    except Exception as e:
        print(f"[RespondToMeeting] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': f'Failed to respond to meeting proposal: {str(e)}'
        })