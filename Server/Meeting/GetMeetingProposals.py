from _Lib import Database
import json
from datetime import datetime

def get_meeting_proposals(session_id, listing_id):
    """Get all meeting proposals for a specific listing"""
    try:
        print(f"[GetMeetingProposals] Getting meeting proposals for listing: {listing_id}")
        
        if not session_id or not listing_id:
            return json.dumps({
                'success': False,
                'error': 'Session ID and listing ID are required'
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
        
        user_id = session_result['UserId']
        
        # Verify user has access to this listing (either owner or has contact access)
        access_query = """
            SELECT 'owner' as access_type FROM listings WHERE listing_id = %s AND user_id = %s
            UNION ALL
            SELECT 'buyer' as access_type FROM contact_access 
            WHERE listing_id = %s AND user_id = %s AND status = 'active'
        """
        cursor.execute(access_query, (listing_id, user_id, listing_id, user_id))
        access_result = cursor.fetchone()
        
        if not access_result:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'You do not have access to view meeting proposals for this listing'
            })
        
        # Get all meeting proposals for this listing involving this user
        proposals_query = """
            SELECT mp.proposal_id, mp.listing_id, mp.proposer_id, mp.recipient_id,
                   mp.proposed_location, mp.proposed_time, mp.message, mp.status,
                   mp.proposed_at, mp.responded_at, mp.expires_at,
                   u1.FirstName as proposer_first_name, u1.LastName as proposer_last_name,
                   u2.FirstName as recipient_first_name, u2.LastName as recipient_last_name
            FROM meeting_proposals mp
            JOIN users u1 ON mp.proposer_id = u1.UserId
            JOIN users u2 ON mp.recipient_id = u2.UserId
            WHERE mp.listing_id = %s 
            AND (mp.proposer_id = %s OR mp.recipient_id = %s)
            ORDER BY mp.proposed_at DESC
        """
        cursor.execute(proposals_query, (listing_id, user_id, user_id))
        proposals = cursor.fetchall()
        
        # Get current agreed meeting from exchange_negotiations (primary source)
        # This is the actual agreed meeting that has been finalized
        agreed_query = """
            SELECT 'exchange' as meeting_type, NULL as proposal_id, NULL as proposed_location, 
                   current_proposed_time as proposed_time, NULL as message,
                   NULL as proposed_at, agreement_reached_at as responded_at,
                   NULL as proposer_first_name, NULL as proposer_last_name,
                   NULL as recipient_first_name, NULL as recipient_last_name
            FROM exchange_negotiations
            WHERE listing_id = %s 
            AND status IN ('agreed', 'paid_partial', 'paid_complete')
            ORDER BY agreement_reached_at DESC
            LIMIT 1
        """
        cursor.execute(agreed_query, (listing_id,))
        accepted_meeting = cursor.fetchone()
        
        # If no agreed meeting in exchange_negotiations, check meeting_proposals for accepted status (fallback)
        if not accepted_meeting:
            accepted_query = """
                SELECT 'proposal' as meeting_type, mp.proposal_id, mp.proposed_location, mp.proposed_time, mp.message,
                       mp.proposed_at, mp.responded_at,
                       u1.FirstName as proposer_first_name, u1.LastName as proposer_last_name,
                       u2.FirstName as recipient_first_name, u2.LastName as recipient_last_name
                FROM meeting_proposals mp
                JOIN users u1 ON mp.proposer_id = u1.UserId
                JOIN users u2 ON mp.recipient_id = u2.UserId
                WHERE mp.listing_id = %s 
                AND (mp.proposer_id = %s OR mp.recipient_id = %s)
                AND mp.status = 'accepted'
                ORDER BY mp.responded_at DESC
                LIMIT 1
            """
            cursor.execute(accepted_query, (listing_id, user_id, user_id))
            accepted_meeting = cursor.fetchone()
        
        connection.close()
        
        # Format proposals
        formatted_proposals = []
        for proposal in proposals:
            # Ensure datetimes are treated as UTC
            proposed_time = proposal['proposed_time']
            if proposed_time and proposed_time.tzinfo is None:
                from datetime import timezone
                proposed_time = proposed_time.replace(tzinfo=timezone.utc)
            
            formatted_proposals.append({
                'proposal_id': proposal['proposal_id'],
                'listing_id': proposal['listing_id'],
                'proposed_location': proposal['proposed_location'],
                'proposed_time': proposed_time.isoformat() if proposed_time else None,
                'message': proposal['message'],
                'status': proposal['status'],
                'proposed_at': proposal['proposed_at'].isoformat() if proposal['proposed_at'] else None,
                'responded_at': proposal['responded_at'].isoformat() if proposal['responded_at'] else None,
                'expires_at': proposal['expires_at'].isoformat() if proposal['expires_at'] else None,
                'is_from_me': proposal['proposer_id'] == user_id,
                'proposer': {
                    'first_name': proposal['proposer_first_name'],
                    'last_name': proposal['proposer_last_name']
                },
                'recipient': {
                    'first_name': proposal['recipient_first_name'],
                    'last_name': proposal['recipient_last_name']
                }
            })
        
        # Format accepted meeting
        current_meeting = None
        if accepted_meeting:
            # Ensure the datetime is treated as UTC
            proposed_time = accepted_meeting['proposed_time']
            if proposed_time and proposed_time.tzinfo is None:
                # Assume naive datetimes from DB are in UTC
                from datetime import timezone
                proposed_time = proposed_time.replace(tzinfo=timezone.utc)
            
            responded_at = accepted_meeting['responded_at']
            if responded_at and responded_at.tzinfo is None:
                from datetime import timezone
                responded_at = responded_at.replace(tzinfo=timezone.utc)
            
            current_meeting = {
                'proposal_id': accepted_meeting['proposal_id'],
                'location': accepted_meeting['proposed_location'],
                'time': proposed_time.isoformat() if proposed_time else None,
                'message': accepted_meeting['message'],
                'proposed_at': accepted_meeting['proposed_at'].isoformat() if accepted_meeting['proposed_at'] else None,
                'agreed_at': responded_at.isoformat() if responded_at else None,
                'proposer': {
                    'first_name': accepted_meeting['proposer_first_name'],
                    'last_name': accepted_meeting['proposer_last_name']
                },
                'recipient': {
                    'first_name': accepted_meeting['recipient_first_name'],
                    'last_name': accepted_meeting['recipient_last_name']
                }
            }
            print(f"[GetMeetingProposals] Meeting time with TZ: {current_meeting['time']}")
        
        print(f"[GetMeetingProposals] Found {len(formatted_proposals)} proposals, accepted meeting: {current_meeting is not None}")
        
        return json.dumps({
            'success': True,
            'proposals': formatted_proposals,
            'current_meeting': current_meeting,
            'user_access_type': access_result['access_type']
        })
        
    except Exception as e:
        print(f"[GetMeetingProposals] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': f'Failed to get meeting proposals: {str(e)}'
        })