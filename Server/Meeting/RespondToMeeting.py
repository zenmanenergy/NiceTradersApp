from _Lib import Database
import json
from datetime import datetime

def respond_to_meeting(session_id, proposal_type, proposal_id, response):
    """Accept or reject a meeting proposal (using new normalized tables)"""
    try:
        print(f"[RespondToMeeting] Processing {response} for {proposal_type} proposal: {proposal_id}")
        
        if not all([session_id, proposal_type, proposal_id, response]):
            return json.dumps({
                'success': False,
                'error': 'Missing required parameters'
            })
        
        if response not in ['accepted', 'rejected']:
            return json.dumps({
                'success': False,
                'error': 'Response must be "accepted" or "rejected"'
            })
        
        # Connect to database
        cursor, connection = Database.ConnectToDatabase()
        
        # Verify session
        cursor.execute("SELECT user_id FROM usersessions WHERE SessionId = %s", (session_id,))
        session_result = cursor.fetchone()
        
        if not session_result:
            connection.close()
            return json.dumps({'success': False, 'error': 'Invalid session'})
        
        user_id = session_result['user_id']
        
        # Handle different proposal types
        if proposal_type == 'time':
            # Update listing_meeting_time
            timestamp_field = 'accepted_at' if response == 'accepted' else 'rejected_at'
            
            cursor.execute(f"""
                UPDATE listing_meeting_time 
                SET {timestamp_field} = NOW(), updated_at = NOW()
                WHERE time_negotiation_id = %s
            """, (proposal_id,))
            
            # Get listing_id for response
            cursor.execute("""
                SELECT listing_id FROM listing_meeting_time 
                WHERE time_negotiation_id = %s
            """, (proposal_id,))
            result = cursor.fetchone()
            listing_id = result['listing_id'] if result else None
            
        elif proposal_type == 'location':
            # Update listing_meeting_location
            timestamp_field = 'accepted_at' if response == 'accepted' else 'rejected_at'
            
            cursor.execute(f"""
                UPDATE listing_meeting_location 
                SET {timestamp_field} = NOW(), updated_at = NOW()
                WHERE location_negotiation_id = %s
            """, (proposal_id,))
            
            # Get listing_id for response
            cursor.execute("""
                SELECT listing_id FROM listing_meeting_location 
                WHERE location_negotiation_id = %s
            """, (proposal_id,))
            result = cursor.fetchone()
            listing_id = result['listing_id'] if result else None
        else:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'Invalid proposal type'
            })
        
        if not listing_id:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'Proposal not found'
            })
        
        connection.commit()
        connection.close()
        
        print(f"[RespondToMeeting] {proposal_type} proposal {response.upper()}: {proposal_id}")
        
        return json.dumps({
            'success': True,
            'message': f'Proposal {response} successfully',
            'listing_id': listing_id
        })
        
    except Exception as e:
        print(f"[RespondToMeeting] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': f'Failed to process response: {str(e)}'
        })
