from _Lib import Database
import json

def get_meeting_proposals(session_id, listing_id):
    """Get all meeting proposals for a listing (using new normalized tables)"""
    try:
        print(f"[GetMeetingProposals] Fetching proposals for listing: {listing_id}")
        
        if not session_id or not listing_id:
            return json.dumps({
                'success': False,
                'error': 'Session ID and listing ID are required'
            })
        
        # Connect to database
        cursor, connection = Database.ConnectToDatabase()
        
        # Verify session
        cursor.execute("SELECT UserId FROM usersessions WHERE SessionId = %s", (session_id,))
        session_result = cursor.fetchone()
        
        if not session_result:
            connection.close()
            return json.dumps({'success': False, 'error': 'Invalid session'})
        
        user_id = session_result['UserId']
        
        # Get current listing to verify access
        cursor.execute("""
            SELECT user_id, buyer_id FROM listings WHERE listing_id = %s
        """, (listing_id,))
        listing_result = cursor.fetchone()
        
        if not listing_result:
            connection.close()
            return json.dumps({'success': False, 'error': 'Listing not found'})
        
        listing_owner_id = listing_result['user_id']
        buyer_id = listing_result['buyer_id']
        
        # Verify user has access (is either owner or buyer)
        if user_id != listing_owner_id and user_id != buyer_id:
            connection.close()
            return json.dumps({'success': False, 'error': 'Access denied'})
        
        response = {
            'success': True,
            'proposals': [],
            'current_meeting': None
        }
        
        # Get time proposals
        cursor.execute("""
            SELECT time_negotiation_id, meeting_time, accepted_at, rejected_at, proposed_by
            FROM listing_meeting_time
            WHERE listing_id = %s
            ORDER BY created_at DESC
        """, (listing_id,))
        
        time_proposals = cursor.fetchall()
        for proposal in time_proposals:
            status = 'accepted' if proposal['accepted_at'] else ('rejected' if proposal['rejected_at'] else 'proposed')
            response['proposals'].append({
                'proposal_id': proposal['time_negotiation_id'],
                'type': 'time',
                'proposed_time': proposal['meeting_time'].isoformat() if proposal['meeting_time'] else None,
                'proposed_by': proposal['proposed_by'],
                'status': status,
                'created_at': proposal['created_at'].isoformat() if 'created_at' in proposal else None
            })
            
            # If this is the accepted time, include it in current_meeting
            if status == 'accepted':
                response['current_meeting'] = {
                    'time': proposal['meeting_time'].isoformat() if proposal['meeting_time'] else None,
                    'location': '',
                    'agreed_at': proposal['accepted_at'].isoformat() if proposal['accepted_at'] else None
                }
        
        # Get location proposals
        cursor.execute("""
            SELECT location_negotiation_id, meeting_location_lat, meeting_location_lng, 
                   meeting_location_name, accepted_at, rejected_at, proposed_by
            FROM listing_meeting_location
            WHERE listing_id = %s
            ORDER BY created_at DESC
        """, (listing_id,))
        
        location_proposals = cursor.fetchall()
        for proposal in location_proposals:
            status = 'accepted' if proposal['accepted_at'] else ('rejected' if proposal['rejected_at'] else 'proposed')
            response['proposals'].append({
                'proposal_id': proposal['location_negotiation_id'],
                'type': 'location',
                'proposed_location': proposal['meeting_location_name'],
                'latitude': float(proposal['meeting_location_lat']) if proposal['meeting_location_lat'] else None,
                'longitude': float(proposal['meeting_location_lng']) if proposal['meeting_location_lng'] else None,
                'proposed_by': proposal['proposed_by'],
                'status': status,
                'created_at': proposal['created_at'].isoformat() if 'created_at' in proposal else None
            })
            
            # If this is the accepted location, update current_meeting
            if status == 'accepted' and response['current_meeting']:
                response['current_meeting']['location'] = proposal['meeting_location_name']
        
        connection.close()
        
        print(f"[GetMeetingProposals] Returning {len(response['proposals'])} proposals")
        return json.dumps(response)
        
    except Exception as e:
        print(f"[GetMeetingProposals] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': f'Failed to fetch proposals: {str(e)}'
        })
