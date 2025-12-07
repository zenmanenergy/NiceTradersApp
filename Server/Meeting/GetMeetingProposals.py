from _Lib import Database
import json
from datetime import datetime, timezone

def get_meeting_proposals(session_id, listing_id):
    """Get all meeting proposals for a specific listing from negotiation_history"""
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
        
        # Get negotiation for this listing
        negotiation_query = """
            SELECT negotiation_id FROM exchange_negotiations
            WHERE listing_id = %s
            LIMIT 1
        """
        cursor.execute(negotiation_query, (listing_id,))
        negotiation = cursor.fetchone()
        
        formatted_proposals = []
        current_meeting = None
        
        if negotiation:
            negotiation_id = negotiation['negotiation_id']
            
            # Get all history records (both time and location proposals)
            history_query = """
                SELECT nh.history_id, nh.action, nh.proposed_time, nh.proposed_location,
                       nh.proposed_latitude, nh.proposed_longitude, nh.proposed_by, nh.notes, nh.created_at,
                       u.FirstName, u.LastName
                FROM negotiation_history nh
                JOIN users u ON nh.proposed_by = u.UserId
                WHERE nh.negotiation_id = %s
                ORDER BY nh.created_at DESC
            """
            cursor.execute(history_query, (negotiation_id,))
            history_records = cursor.fetchall()
            
            for record in history_records:
                proposed_time = record['proposed_time']
                if proposed_time and proposed_time.tzinfo is None:
                    proposed_time = proposed_time.replace(tzinfo=timezone.utc)
                
                # Determine status based on action
                status = 'pending'
                if record['action'] == 'accepted':
                    status = 'accepted'
                elif record['action'] == 'rejected':
                    status = 'rejected'
                
                formatted_proposals.append({
                    'proposal_id': record['history_id'],
                    'proposed_location': record['proposed_location'],
                    'proposed_latitude': record['proposed_latitude'],
                    'proposed_longitude': record['proposed_longitude'],
                    'proposed_time': proposed_time.isoformat() if proposed_time else None,
                    'message': record['notes'],
                    'status': status,
                    'action': record['action'],
                    'proposed_at': record['created_at'].isoformat() if record['created_at'] else None,
                    'is_from_me': record['proposed_by'] == user_id,
                    'proposer': {
                        'first_name': record['FirstName'],
                        'last_name': record['LastName']
                    }
                })
            
            # Get current agreed meeting from most recent accepted record
            accepted_query = """
                SELECT nh.history_id, nh.accepted_time, nh.accepted_location,
                       nh.accepted_latitude, nh.accepted_longitude, nh.proposed_location,
                       nh.proposed_latitude, nh.proposed_longitude, nh.proposed_by, nh.notes, nh.created_at,
                       u.FirstName, u.LastName
                FROM negotiation_history nh
                JOIN users u ON nh.proposed_by = u.UserId
                WHERE nh.negotiation_id = %s
                AND nh.action IN ('accepted_time', 'accepted_location')
                AND nh.accepted_time IS NOT NULL
                ORDER BY nh.created_at DESC
                LIMIT 1
            """
            cursor.execute(accepted_query, (negotiation_id,))
            accepted_record = cursor.fetchone()
            
            if accepted_record:
                accepted_time = accepted_record['accepted_time']
                if accepted_time and accepted_time.tzinfo is None:
                    accepted_time = accepted_time.replace(tzinfo=timezone.utc)
                
                # Use accepted_location if available, fall back to proposed_location
                location = accepted_record['accepted_location'] or accepted_record['proposed_location']
                latitude = accepted_record['accepted_latitude'] or accepted_record['proposed_latitude']
                longitude = accepted_record['accepted_longitude'] or accepted_record['proposed_longitude']
                
                current_meeting = {
                    'proposal_id': accepted_record['history_id'],
                    'location': location,
                    'latitude': latitude,
                    'longitude': longitude,
                    'time': accepted_time.isoformat() if accepted_time else None,
                    'message': accepted_record['notes'],
                    'proposed_at': accepted_record['created_at'].isoformat() if accepted_record['created_at'] else None,
                    'agreed_at': accepted_record['created_at'].isoformat() if accepted_record['created_at'] else None,
                    'proposer': {
                        'first_name': accepted_record['FirstName'],
                        'last_name': accepted_record['LastName']
                    }
                }
                print(f"[GetMeetingProposals] Meeting time with TZ: {current_meeting['time']}")
        
        connection.close()
        
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