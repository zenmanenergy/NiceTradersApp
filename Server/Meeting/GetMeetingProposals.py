from _Lib import Database
from Dashboard.GetUserDashboard import calculate_negotiation_status
import json
from datetime import timezone

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
        cursor.execute("SELECT user_id FROM usersessions WHERE SessionId = %s", (session_id,))
        session_result = cursor.fetchone()
        
        if not session_result:
            print(f"🔴 [GetMeetingProposals] ERROR: Invalid session")
            connection.close()
            return json.dumps({'success': False, 'error': 'Invalid session'})
        
        user_id = session_result['user_id']
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
        
        # Check if user has proposed a time (is a negotiator on this listing)
        cursor.execute("""
            SELECT buyer_id FROM listing_meeting_time WHERE listing_id = %s AND buyer_id = %s
        """, (listing_id, user_id))
        proposed_result = cursor.fetchone()
        
        # Verify user has access (is owner, accepted buyer, or has proposed a time)
        if user_id != listing_owner_id and user_id != buyer_id and not proposed_result:
            print(f"🔴 [GetMeetingProposals] ERROR: Access denied for user {user_id}")
            connection.close()
            return json.dumps({'success': False, 'error': 'Access denied'})
        
        # Get exchange data for displayStatus calculation
        cursor.execute("""
            SELECT 
                l.listing_id, lmt.buyer_id, l.user_id as seller_id,
                lmt.proposed_by, lmt.meeting_time, lmt.accepted_at, lmt.rejected_at,
                lp.buyer_paid_at, lp.seller_paid_at,
                CASE WHEN lml.location_negotiation_id IS NOT NULL THEN 1 ELSE 0 END as has_location_proposal,
                lml.proposed_by as location_proposed_by,
                lml.accepted_at as location_accepted_at
            FROM listings l
            JOIN listing_meeting_time lmt ON l.listing_id = lmt.listing_id
            LEFT JOIN listing_payments lp ON l.listing_id = lp.listing_id
            LEFT JOIN listing_meeting_location lml ON l.listing_id = lml.listing_id
            WHERE l.listing_id = %s
            LIMIT 1
        """, (listing_id,))
        exchange_data = cursor.fetchone()
        
        display_status = None
        if exchange_data:
            display_status = calculate_negotiation_status(exchange_data, user_id)
            print(f"🟠 [GetMeetingProposals] Calculated displayStatus: {display_status}")
        
        response = {
            'success': True,
            'proposals': [],
            'current_meeting': None,
            'displayStatus': display_status
        }
        
        # Get time proposals
        print(f"🟠 [GetMeetingProposals] Fetching time proposals...")
        cursor.execute("""
            SELECT t.time_negotiation_id, t.meeting_time, t.accepted_at, t.rejected_at, t.proposed_by, t.created_at, t.updated_at,
                   u.FirstName as proposer_name
            FROM listing_meeting_time t
            LEFT JOIN users u ON t.proposed_by = u.user_id
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
            
            # Convert naive datetime to UTC ISO format
            proposed_time_str = None
            if proposal['meeting_time']:
                # Assume stored time is in UTC
                dt_with_tz = proposal['meeting_time'].replace(tzinfo=timezone.utc)
                proposed_time_str = dt_with_tz.isoformat()
            
            response['proposals'].append({
                'proposal_id': proposal['time_negotiation_id'],
                'type': 'time',
                'proposed_time': proposed_time_str,
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
                accepted_at_str = None
                if proposal['accepted_at']:
                    dt_with_tz = proposal['accepted_at'].replace(tzinfo=timezone.utc)
                    accepted_at_str = dt_with_tz.isoformat()
                
                response['current_meeting'] = {
                    'time': proposed_time_str,
                    'location': None,
                    'latitude': None,
                    'longitude': None,
                    'agreed_at': accepted_at_str,
                    'timeAcceptedAt': accepted_at_str,
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
            LEFT JOIN users u ON l.proposed_by = u.user_id
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
                location_accepted_at_str = None
                if proposal['accepted_at']:
                    dt_with_tz = proposal['accepted_at'].replace(tzinfo=timezone.utc)
                    location_accepted_at_str = dt_with_tz.isoformat()
                
                if response['current_meeting']:
                    response['current_meeting']['location'] = proposal['meeting_location_name']
                    response['current_meeting']['latitude'] = float(proposal['meeting_location_lat']) if proposal['meeting_location_lat'] else None
                    response['current_meeting']['longitude'] = float(proposal['meeting_location_lng']) if proposal['meeting_location_lng'] else None
                    response['current_meeting']['locationAcceptedAt'] = location_accepted_at_str
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
                        'locationAcceptedAt': location_accepted_at_str
                    }
                    print(f"  ✅ Location accepted at: {proposal['accepted_at']} (no time accepted yet)")
        
        # Get payment information (regardless of whether time/location is accepted)
        print(f"🟠 [GetMeetingProposals] Fetching payment information...")
        
        # Get listing and buyer info - buyer_id comes from listing_meeting_time, seller from listings.user_id
        cursor.execute("""
            SELECT l.user_id as seller_id, lmt.buyer_id 
            FROM listings l
            LEFT JOIN listing_meeting_time lmt ON l.listing_id = lmt.listing_id
            WHERE l.listing_id = %s
            LIMIT 1
        """, (listing_id,))
        listing_info = cursor.fetchone()
        seller_id = listing_info['seller_id']
        buyer_id = listing_info['buyer_id']
        is_current_user_buyer = (user_id == buyer_id)
        
        print(f"🟠 [GetMeetingProposals] User roles - seller: {seller_id}, buyer: {buyer_id}, current user is buyer: {is_current_user_buyer}")
        
        cursor.execute("""
            SELECT buyer_paid_at, seller_paid_at FROM listing_payments
            WHERE listing_id = %s
        """, (listing_id,))
        payment_result = cursor.fetchone()
        
        user_paid_at = None
        other_user_paid_at = None
        
        if payment_result:
            buyer_paid_at = None
            seller_paid_at = None
            if payment_result['buyer_paid_at']:
                dt_with_tz = payment_result['buyer_paid_at'].replace(tzinfo=timezone.utc)
                buyer_paid_at = dt_with_tz.isoformat()
            if payment_result['seller_paid_at']:
                dt_with_tz = payment_result['seller_paid_at'].replace(tzinfo=timezone.utc)
                seller_paid_at = dt_with_tz.isoformat()
            
            # Map based on current user's role
            if is_current_user_buyer:
                user_paid_at = buyer_paid_at
                other_user_paid_at = seller_paid_at
            else:
                user_paid_at = seller_paid_at
                other_user_paid_at = buyer_paid_at
            
            print(f"  ✅ Payment info - buyer paid: {buyer_paid_at}, seller paid: {seller_paid_at}")
            print(f"  ✅ Current user ({user_id}) paid: {user_paid_at}, other user paid: {other_user_paid_at}")
        else:
            print(f"  ⏳ No payment record yet")
        
        # Add payment info to current_meeting if it exists
        if response['current_meeting']:
            response['current_meeting']['userPaidAt'] = user_paid_at
            response['current_meeting']['otherUserPaidAt'] = other_user_paid_at
        else:
            # Even if no current_meeting exists, return payment info at top level for UI to use
            response['userPaidAt'] = user_paid_at
            response['otherUserPaidAt'] = other_user_paid_at
            print(f"🟠 [GetMeetingProposals] No current_meeting, returning payment info at top level")
        
        connection.close()
        
        print(f"✅ [GetMeetingProposals] SUCCESS: Returning {len(response['proposals'])} proposals")
        print(f"✅ [GetMeetingProposals] Current meeting: {response['current_meeting']}")
        print(f"✅ [GetMeetingProposals] Top-level userPaidAt: {response.get('userPaidAt', 'N/A')}")
        print(f"✅ [GetMeetingProposals] Top-level otherUserPaidAt: {response.get('otherUserPaidAt', 'N/A')}")
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

