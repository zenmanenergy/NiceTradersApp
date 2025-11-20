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
        
        # Get current accepted meeting (if any)
        accepted_query = """
            SELECT mp.proposal_id, mp.proposed_location, mp.proposed_time, mp.message,
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
            formatted_proposals.append({
                'proposal_id': proposal['proposal_id'],
                'listing_id': proposal['listing_id'],
                'proposed_location': proposal['proposed_location'],
                'proposed_time': proposal['proposed_time'].isoformat() if proposal['proposed_time'] else None,
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
            current_meeting = {
                'proposal_id': accepted_meeting['proposal_id'],
                'location': accepted_meeting['proposed_location'],
                'time': accepted_meeting['proposed_time'].isoformat() if accepted_meeting['proposed_time'] else None,
                'message': accepted_meeting['message'],
                'proposed_at': accepted_meeting['proposed_at'].isoformat() if accepted_meeting['proposed_at'] else None,
                'agreed_at': accepted_meeting['responded_at'].isoformat() if accepted_meeting['responded_at'] else None,
                'proposer': {
                    'first_name': accepted_meeting['proposer_first_name'],
                    'last_name': accepted_meeting['proposer_last_name']
                },
                'recipient': {
                    'first_name': accepted_meeting['recipient_first_name'],
                    'last_name': accepted_meeting['recipient_last_name']
                }
            }
        
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