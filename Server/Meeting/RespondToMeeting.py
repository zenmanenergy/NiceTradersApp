from _Lib import Database
import json
from datetime import datetime

def respond_to_meeting(session_id, proposal_id, response):
    """Accept or reject a meeting proposal"""
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
        
        # Get proposal details and verify user is the recipient
        proposal_query = """
            SELECT mp.proposal_id, mp.listing_id, mp.proposer_id, mp.recipient_id,
                   mp.proposed_location, mp.proposed_time, mp.message, mp.status,
                   u1.FirstName as proposer_first_name, u1.LastName as proposer_last_name,
                   u2.FirstName as recipient_first_name, u2.LastName as recipient_last_name
            FROM meeting_proposals mp
            JOIN users u1 ON mp.proposer_id = u1.UserId
            JOIN users u2 ON mp.recipient_id = u2.UserId
            WHERE mp.proposal_id = %s
        """
        cursor.execute(proposal_query, (proposal_id,))
        proposal_result = cursor.fetchone()
        
        if not proposal_result:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'Meeting proposal not found'
            })
        
        if proposal_result['recipient_id'] != user_id:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'You can only respond to proposals sent to you'
            })
        
        if proposal_result['status'] != 'pending':
            connection.close()
            return json.dumps({
                'success': False,
                'error': f'This proposal has already been {proposal_result["status"]}'
            })
        
        # Update proposal status
        update_query = """
            UPDATE meeting_proposals 
            SET status = %s, responded_at = NOW()
            WHERE proposal_id = %s
        """
        cursor.execute(update_query, (response, proposal_id))
        
        # If accepted, expire any other pending proposals for this listing between these users
        if response == 'accepted':
            expire_others_query = """
                UPDATE meeting_proposals 
                SET status = 'expired' 
                WHERE listing_id = %s 
                AND ((proposer_id = %s AND recipient_id = %s) OR (proposer_id = %s AND recipient_id = %s))
                AND proposal_id != %s
                AND status = 'pending'
            """
            cursor.execute(expire_others_query, (
                proposal_result['listing_id'], 
                proposal_result['proposer_id'], 
                proposal_result['recipient_id'],
                proposal_result['recipient_id'], 
                proposal_result['proposer_id'], 
                proposal_id
            ))
        
        connection.commit()
        connection.close()
        
        print(f"[RespondToMeeting] Proposal {proposal_id} {response} successfully")
        
        return json.dumps({
            'success': True,
            'message': f'Meeting proposal {response} successfully',
            'proposal': {
                'proposal_id': proposal_result['proposal_id'],
                'listing_id': proposal_result['listing_id'],
                'proposed_location': proposal_result['proposed_location'],
                'proposed_time': proposal_result['proposed_time'].isoformat() if proposal_result['proposed_time'] else None,
                'message': proposal_result['message'],
                'status': response,
                'proposer': {
                    'first_name': proposal_result['proposer_first_name'],
                    'last_name': proposal_result['proposer_last_name']
                },
                'recipient': {
                    'first_name': proposal_result['recipient_first_name'],
                    'last_name': proposal_result['recipient_last_name']
                }
            }
        })
        
    except Exception as e:
        print(f"[RespondToMeeting] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': f'Failed to respond to meeting proposal: {str(e)}'
        })