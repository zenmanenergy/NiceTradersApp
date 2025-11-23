from _Lib import Database
import json
from datetime import datetime, timedelta

def get_exact_location(session_id, listing_id):
    """
    Get exact location for a listing - only allowed within 1 hour of agreed meeting time
    Returns approximate location otherwise
    """
    try:
        print(f"[GetExactLocation] Request for listing: {listing_id}")
        
        if not session_id or not listing_id:
            return json.dumps({
                'success': False,
                'error': 'Session ID and listing ID are required'
            })
        
        # Connect to database
        cursor, connection = Database.ConnectToDatabase()
        
        # Verify session and get user ID
        cursor.execute("SELECT UserId FROM usersessions WHERE SessionId = %s", (session_id,))
        session_result = cursor.fetchone()
        
        if not session_result:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'Invalid or expired session'
            })
        
        user_id = session_result['UserId']
        
        # Check if user has an accepted meeting for this listing
        meeting_query = """
            SELECT mp.proposal_id, mp.proposed_time, mp.proposed_location,
                   l.latitude, l.longitude, l.location
            FROM meeting_proposals mp
            JOIN listings l ON mp.listing_id = l.listing_id
            WHERE mp.listing_id = %s
            AND (mp.proposer_id = %s OR mp.recipient_id = %s)
            AND mp.status = 'accepted'
            ORDER BY mp.responded_at DESC
            LIMIT 1
        """
        cursor.execute(meeting_query, (listing_id, user_id, user_id))
        meeting = cursor.fetchone()
        
        if not meeting:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'No accepted meeting found for this listing',
                'has_meeting': False
            })
        
        # Check if we're within 1 hour of the meeting time
        proposed_time = meeting['proposed_time']
        current_time = datetime.now()
        time_until_meeting = (proposed_time - current_time).total_seconds() / 3600  # hours
        time_since_meeting = (current_time - proposed_time).total_seconds() / 3600  # hours
        
        # Allow access 1 hour before and up to 2 hours after meeting time
        is_meeting_time = (-1 <= time_until_meeting <= 2)
        
        connection.close()
        
        if is_meeting_time:
            # Reveal exact location
            print(f"[GetExactLocation] Revealing exact location - meeting in {time_until_meeting:.1f} hours")
            return json.dumps({
                'success': True,
                'has_meeting': True,
                'is_exact': True,
                'location': {
                    'address': meeting['proposed_location'],
                    'latitude': float(meeting['latitude']) if meeting['latitude'] else None,
                    'longitude': float(meeting['longitude']) if meeting['longitude'] else None
                },
                'meeting_time': proposed_time.isoformat(),
                'time_until_meeting_hours': time_until_meeting
            })
        else:
            # Return approximate location
            print(f"[GetExactLocation] Too early - meeting in {time_until_meeting:.1f} hours")
            return json.dumps({
                'success': True,
                'has_meeting': True,
                'is_exact': False,
                'location': {
                    'address': meeting['location'],  # General area only
                    'latitude': None,
                    'longitude': None
                },
                'meeting_time': proposed_time.isoformat(),
                'time_until_meeting_hours': time_until_meeting,
                'message': 'Exact location will be revealed 1 hour before your meeting'
            })
        
    except Exception as e:
        print(f"[GetExactLocation] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': f'Failed to get location: {str(e)}'
        })
