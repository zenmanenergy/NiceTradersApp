from _Lib import Database
import json

def get_meeting_proposals(session_id, listing_id):
    """Get all meeting proposals for a listing (using new normalized tables)"""
    try:
        print(f"\n🟠 [GetMeetingProposals] ===== START GET PROPOSALS =====")
        print(f"🟠 [GetMeetingProposals] Input: listing_id={listing_id}, session_id={session_id}")
        
        if not session_id or not listing_id:
            print(f"🔴 [GetMeetingProposals] ERROR: Missing required parameters")
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
            print(f"🔴 [GetMeetingProposals] ERROR: Invalid session")
            connection.close()
            return json.dumps({'success': False, 'error': 'Invalid session'})
        
        user_id = session_result['UserId']
        print(f"🟠 [GetMeetingProposals] Session verified - user_id: {user_id}")
        
        # Get current listing to verify access
        cursor.execute("""
            SELECT user_id, buyer_id FROM listings WHERE listing_id = %s
        """, (listing_id,))
        listing_result = cursor.fetchone()
        
        if not listing_result:
            print(f"🔴 [GetMeetingProposals] ERROR: Listing not found: {listing_id}")
            connection.close()
            return json.dumps({'success': False, 'error': 'Listing not found'})
        
        listing_owner_id = listing_result['user_id']
        buyer_id = listing_result['buyer_id']
        print(f"🟠 [GetMeetingProposals] Listing found - owner: {listing_owner_id}, buyer: {buyer_id}")
        
        # Verify user has access (is either owner or buyer)
        if user_id != listing_owner_id and user_id != buyer_id:
            print(f"🔴 [GetMeetingProposals] ERROR: Access denied for user {user_id}")
            connection.close()
            return json.dumps({'success': False, 'error': 'Access denied'})
        
        response = {
            'success': True,
            'proposals': [],
            'current_meeting': None
        }
        
        # Get time proposals
        print(f"🟠 [GetMeetingProposals] Fetching time proposals...")
        cursor.execute("""
            SELECT t.time_negotiation_id, t.meeting_time, t.accepted_at, t.rejected_at, t.proposed_by, t.created_at, t.updated_at,
                   u.FirstName as proposer_name
            FROM listing_meeting_time t
            LEFT JOIN users u ON t.proposed_by = u.UserId
            WHERE t.listing_id = %s
            ORDER BY t.created_at DESC
        """, (listing_id,))
        
        time_proposals = cursor.fetchall()
        print(f"🟠 [GetMeetingProposals] Found {len(time_proposals)} time proposals")
        
        time_accepted_at = None
        for proposal in time_proposals:
            status = 'accepted' if proposal['accepted_at'] else ('rejected' if proposal['rejected_at'] else 'pending')
            proposer_name = proposal.get('proposer_name') or 'Unknown'
            print(f"  - Time proposal: id={proposal['time_negotiation_id']}, status={status}, time={proposal['meeting_time']}, proposed_by={proposer_name}")
            
            response['proposals'].append({
                'proposal_id': proposal['time_negotiation_id'],
                'type': 'time',
                'proposed_time': proposal['meeting_time'].isoformat() if proposal['meeting_time'] else None,
                'proposed_location': '',
                'proposed_by_id': proposal['proposed_by'],
                'proposed_by_name': proposer_name,
                'status': status,
                'is_from_me': proposal['proposed_by'] == user_id,
                'created_at': proposal['created_at'].isoformat() if 'created_at' in proposal else None
            })
            
            # If this is the accepted time, store it for current_meeting
            if status == 'accepted':
                time_accepted_at = proposal['accepted_at']
                response['current_meeting'] = {
                    'time': proposal['meeting_time'].isoformat() if proposal['meeting_time'] else None,
                    'location': None,
                    'latitude': None,
                    'longitude': None,
                    'agreed_at': proposal['accepted_at'].isoformat() if proposal['accepted_at'] else None,
                    'timeAcceptedAt': proposal['accepted_at'].isoformat() if proposal['accepted_at'] else None,
                    'locationAcceptedAt': None
                }
                print(f"  ✅ Time accepted at: {time_accepted_at}")
        
        # Get location proposals
        print(f"🟠 [GetMeetingProposals] Fetching location proposals...")
        cursor.execute("""
            SELECT l.location_negotiation_id, l.meeting_location_lat, l.meeting_location_lng, 
                   l.meeting_location_name, l.accepted_at, l.rejected_at, l.proposed_by, l.created_at, l.updated_at,
                   u.FirstName as proposer_name
            FROM listing_meeting_location l
            LEFT JOIN users u ON l.proposed_by = u.UserId
            WHERE l.listing_id = %s
            ORDER BY l.created_at DESC
        """, (listing_id,))
        
        location_proposals = cursor.fetchall()
        print(f"🟠 [GetMeetingProposals] Found {len(location_proposals)} location proposals")
        
        for proposal in location_proposals:
            status = 'accepted' if proposal['accepted_at'] else ('rejected' if proposal['rejected_at'] else 'pending')
            proposer_name = proposal.get('proposer_name') or 'Unknown'
            print(f"  - Location proposal: id={proposal['location_negotiation_id']}, status={status}, location={proposal['meeting_location_name']}, proposed_by={proposer_name}")
            
            response['proposals'].append({
                'proposal_id': proposal['location_negotiation_id'],
                'type': 'location',
                'proposed_location': proposal['meeting_location_name'],
                'proposed_time': '',
                'latitude': float(proposal['meeting_location_lat']) if proposal['meeting_location_lat'] else None,
                'longitude': float(proposal['meeting_location_lng']) if proposal['meeting_location_lng'] else None,
                'proposed_by_id': proposal['proposed_by'],
                'proposed_by_name': proposer_name,
                'status': status,
                'is_from_me': proposal['proposed_by'] == user_id,
                'created_at': proposal['created_at'].isoformat() if 'created_at' in proposal else None
            })
            
            # If this is the accepted location, update current_meeting
            if status == 'accepted':
                if response['current_meeting']:
                    response['current_meeting']['location'] = proposal['meeting_location_name']
                    response['current_meeting']['latitude'] = float(proposal['meeting_location_lat']) if proposal['meeting_location_lat'] else None
                    response['current_meeting']['longitude'] = float(proposal['meeting_location_lng']) if proposal['meeting_location_lng'] else None
                    response['current_meeting']['locationAcceptedAt'] = proposal['accepted_at'].isoformat() if proposal['accepted_at'] else None
                    print(f"  ✅ Location accepted at: {proposal['accepted_at']}")
                else:
                    # Location accepted but no time accepted yet
                    response['current_meeting'] = {
                        'time': None,
                        'location': proposal['meeting_location_name'],
                        'latitude': float(proposal['meeting_location_lat']) if proposal['meeting_location_lat'] else None,
                        'longitude': float(proposal['meeting_location_lng']) if proposal['meeting_location_lng'] else None,
                        'agreed_at': None,
                        'timeAcceptedAt': None,
                        'locationAcceptedAt': proposal['accepted_at'].isoformat() if proposal['accepted_at'] else None
                    }
                    print(f"  ✅ Location accepted at: {proposal['accepted_at']} (no time accepted yet)")
        
        connection.close()
        
        print(f"✅ [GetMeetingProposals] SUCCESS: Returning {len(response['proposals'])} proposals")
        print(f"✅ [GetMeetingProposals] Current meeting: {response['current_meeting']}")
        print(f"🟠 [GetMeetingProposals] ===== END GET PROPOSALS =====\n")
        return json.dumps(response)
        
    except Exception as e:
        print(f"🔴 [GetMeetingProposals] ERROR: {str(e)}")
        import traceback
        traceback.print_exc()
        return json.dumps({
            'success': False,
            'error': f'Failed to fetch proposals: {str(e)}'
        })
