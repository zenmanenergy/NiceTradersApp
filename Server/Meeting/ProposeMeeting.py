from _Lib import Database
import json
import uuid
from datetime import datetime, timedelta

def propose_meeting(session_id, listing_id, proposed_location, proposed_time, message=None):
    """Propose a meeting time and location for an exchange"""
    try:
        print(f"[ProposeMeeting] Creating meeting proposal for listing: {listing_id}")
        
        if not session_id or not listing_id or not proposed_location or not proposed_time:
            return json.dumps({
                'success': False,
                'error': 'Session ID, listing ID, location, and time are required'
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
        
        proposer_id = session_result['UserId']
        
        # Get listing info and determine recipient
        listing_query = """
            SELECT l.user_id as listing_owner_id
            FROM listings l
            WHERE l.listing_id = %s
        """
        cursor.execute(listing_query, (listing_id,))
        listing_result = cursor.fetchone()
        
        if not listing_result:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'Listing not found'
            })
        
        listing_owner_id = listing_result['listing_owner_id']
        
        # Determine recipient based on who is proposing
        if proposer_id == listing_owner_id:
            # Listing owner is proposing - find the buyer from contact_access
            recipient_query = """
                SELECT user_id FROM contact_access 
                WHERE listing_id = %s AND status = 'active'
                ORDER BY purchased_at DESC LIMIT 1
            """
            cursor.execute(recipient_query, (listing_id,))
            recipient_result = cursor.fetchone()
            
            if not recipient_result:
                connection.close()
                return json.dumps({
                    'success': False,
                    'error': 'No active contact access found for this listing'
                })
            recipient_id = recipient_result['user_id']
        else:
            # Buyer is proposing to listing owner
            # Verify buyer has access to this listing
            access_query = """
                SELECT access_id FROM contact_access 
                WHERE listing_id = %s AND user_id = %s AND status = 'active'
            """
            cursor.execute(access_query, (listing_id, proposer_id))
            if not cursor.fetchone():
                connection.close()
                return json.dumps({
                    'success': False,
                    'error': 'You do not have access to propose meetings for this listing'
                })
            recipient_id = listing_owner_id
        
        # Parse proposed time
        try:
            proposed_datetime = datetime.fromisoformat(proposed_time.replace('Z', '+00:00'))
        except ValueError:
            try:
                proposed_datetime = datetime.strptime(proposed_time, '%Y-%m-%d %H:%M:%S')
            except ValueError:
                connection.close()
                return json.dumps({
                    'success': False,
                    'error': 'Invalid datetime format. Use ISO format or YYYY-MM-DD HH:MM:SS'
                })
        
        # Expire any existing pending proposals between these users for this listing
        expire_query = """
            UPDATE meeting_proposals 
            SET status = 'expired' 
            WHERE listing_id = %s 
            AND ((proposer_id = %s AND recipient_id = %s) OR (proposer_id = %s AND recipient_id = %s))
            AND status = 'pending'
        """
        cursor.execute(expire_query, (listing_id, proposer_id, recipient_id, recipient_id, proposer_id))
        
        # Create new proposal (MPR prefix + UUID trimmed to fit CHAR(39))
        proposal_id = f"MPR-{str(uuid.uuid4())[:-1]}"  # 39 chars: MPR- + 35 char UUID
        expires_at = datetime.now() + timedelta(days=7)  # Proposals expire after 7 days
        
        insert_query = """
            INSERT INTO meeting_proposals 
            (proposal_id, listing_id, proposer_id, recipient_id, proposed_location, 
             proposed_time, message, expires_at)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """
        cursor.execute(insert_query, (
            proposal_id, listing_id, proposer_id, recipient_id, 
            proposed_location, proposed_datetime, message, expires_at
        ))
        
        connection.commit()
        connection.close()
        
        print(f"[ProposeMeeting] Meeting proposal created successfully: {proposal_id}")
        
        return json.dumps({
            'success': True,
            'proposal_id': proposal_id,
            'message': 'Meeting proposal sent successfully'
        })
        
    except Exception as e:
        print(f"[ProposeMeeting] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': f'Failed to create meeting proposal: {str(e)}'
        })