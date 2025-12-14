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
        
        # Get payment information if time is accepted
        if response['current_meeting']:
            print(f"🟠 [GetMeetingProposals] Fetching payment information...")
            
            # Get listing details to know who is buyer and seller
            cursor.execute("""
                SELECT user_id, buyer_id FROM listings WHERE listing_id = %s
            """, (listing_id,))
            listing_info = cursor.fetchone()
            seller_id = listing_info['user_id']
            buyer_id = listing_info['buyer_id']
            is_current_user_buyer = (user_id == buyer_id)
            
            print(f"🟠 [GetMeetingProposals] User roles - seller: {seller_id}, buyer: {buyer_id}, current user is buyer: {is_current_user_buyer}")
            
        
        # Get payment information (regardless of whether time/location is accepted)
        print(f"🟠 [GetMeetingProposals] Fetching payment information...")
        
        # Get listing details to know who is buyer and seller
        cursor.execute("""
            SELECT user_id, buyer_id FROM listings WHERE listing_id = %s
        """, (listing_id,))
        listing_info = cursor.fetchone()
        seller_id = listing_info['user_id']
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
            buyer_paid_at = payment_result['buyer_paid_at'].isoformat() if payment_result['buyer_paid_at'] else None
            seller_paid_at = payment_result['seller_paid_at'].isoformat() if payment_result['seller_paid_at'] else None
            
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

