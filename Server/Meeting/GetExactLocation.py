from _Lib import Database
import json
from datetime import datetime, timedelta

def get_exact_location(session_id, listing_id):
    """
    Get exact location for a listing - only allowed within 1 hour of agreed meeting time
    Returns approximate location otherwise (using new normalized tables)
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
        cursor.execute("SELECT user_id FROM usersessions WHERE SessionId = %s", (session_id,))
        session_result = cursor.fetchone()
        
        if not session_result:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'Invalid or expired session'
            })
        
        user_id = session_result['user_id']
        
        # Check if user has an accepted meeting for this listing
        meeting_query = """
            SELECT lml.location_negotiation_id, lml.accepted_at, 
                   lml.meeting_location_lat, lml.meeting_location_lng, lml.meeting_location_name,
                   lmt.meeting_time
            FROM listing_meeting_location lml
            LEFT JOIN listing_meeting_time lmt ON lml.listing_id = lmt.listing_id
            WHERE lml.listing_id = %s
            AND lml.accepted_at IS NOT NULL
            LIMIT 1
        """
        cursor.execute(meeting_query, (listing_id,))
        meeting = cursor.fetchone()
        
        if not meeting:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'No accepted meeting found for this listing',
                'has_meeting': False
            })
        
        # Check if we're within 1 hour of the meeting time
        meeting_time = meeting['meeting_time']
        if not meeting_time:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'No meeting time set for this listing',
                'has_meeting': False
            })
        
        current_time = datetime.now()
        time_until_meeting = (meeting_time - current_time).total_seconds() / 3600  # hours
        
        connection.close()
        
        # Allow access 1 hour before and up to 2 hours after meeting time
        is_meeting_time = (-1 <= time_until_meeting <= 2)
        
        if is_meeting_time:
            # Reveal exact location
            print(f"[GetExactLocation] Revealing exact location - meeting in {time_until_meeting:.1f} hours")
            return json.dumps({
                'success': True,
                'has_meeting': True,
                'is_exact': True,
                'location': {
                    'address': meeting['meeting_location_name'],
                    'latitude': float(meeting['meeting_location_lat']) if meeting['meeting_location_lat'] else None,
                    'longitude': float(meeting['meeting_location_lng']) if meeting['meeting_location_lng'] else None
                },
                'meeting_time': meeting_time.isoformat(),
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
                    'address': meeting['meeting_location_name'],
                    'latitude': None,
                    'longitude': None
                },
                'meeting_time': meeting_time.isoformat(),
                'time_until_meeting_hours': time_until_meeting,
                'message': 'Exact location will be revealed 1 hour before your meeting'
            })
        
    except Exception as e:
        print(f"[GetExactLocation] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': f'Failed to get location: {str(e)}'
        })
