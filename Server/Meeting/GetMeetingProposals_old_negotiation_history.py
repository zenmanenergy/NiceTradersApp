from _Lib import Database
import json
from datetime import datetime, timezone
from decimal import Decimal

def _to_serializable(value):
    """Convert Decimal and other non-serializable types to JSON-safe types"""
    if isinstance(value, Decimal):
        return float(value)
    return value

class DecimalEncoder(json.JSONEncoder):
    """JSON encoder that handles Decimal objects"""
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super().default(obj)

def get_meeting_proposals(session_id, listing_id):
    """Get all meeting proposals for a specific listing from negotiation_history only"""
    try:
        print(f"\n[GetMeetingProposals] ===== START GET PROPOSALS =====")
        print(f"[GetMeetingProposals] session_id: {session_id}, listing_id: {listing_id}")
        
        if not session_id or not listing_id:
            return json.dumps({'success': False, 'error': 'Session ID and listing ID are required'})
        
        cursor, connection = Database.ConnectToDatabase()
        
        # Verify session
        cursor.execute("SELECT user_id FROM usersessions WHERE SessionId = %s", (session_id,))
        session_result = cursor.fetchone()
        if not session_result:
            connection.close()
            return json.dumps({'success': False, 'error': 'Invalid or expired session'})
        
        user_id = session_result['user_id']
        
        # Verify access
        cursor.execute("""
            SELECT 'owner' as access_type FROM listings WHERE listing_id = %s AND user_id = %s
            UNION ALL
            SELECT 'buyer' as access_type FROM contact_access 
            WHERE listing_id = %s AND user_id = %s AND status = 'active'
        """, (listing_id, user_id, listing_id, user_id))
        access_result = cursor.fetchone()
        
        if not access_result:
            connection.close()
            return json.dumps({'success': False, 'error': 'You do not have access to view meeting proposals for this listing'})
        
        # Get negotiation from negotiation_history
        cursor.execute("SELECT DISTINCT negotiation_id FROM negotiation_history WHERE listing_id = %s LIMIT 1", (listing_id,))
        negotiation = cursor.fetchone()
        
        formatted_proposals = []
        current_meeting = None
        
        if negotiation:
            negotiation_id = negotiation['negotiation_id']
            print(f"[GetMeetingProposals] Found negotiation: {negotiation_id}")
            
            # Get all proposal records
            cursor.execute("""
                SELECT nh.history_id, nh.action, nh.proposed_time, nh.proposed_location,
                       nh.proposed_latitude, nh.proposed_longitude, nh.proposed_by, nh.notes, nh.created_at,
                       u.FirstName, u.LastName
                FROM negotiation_history nh
                JOIN users u ON nh.proposed_by = u.user_id
                WHERE nh.negotiation_id = %s
                ORDER BY nh.created_at DESC
            """, (negotiation_id,))
            history_records = cursor.fetchall()
            
            print(f"[GetMeetingProposals] Found {len(history_records)} history records")
            
            for record in history_records:
                proposed_time = record['proposed_time']
                if proposed_time and proposed_time.tzinfo is None:
                    proposed_time = proposed_time.replace(tzinfo=timezone.utc)
                
                status = 'pending'
                if record['action'] in ('accepted', 'accepted_time', 'accepted_location'):
                    status = 'accepted'
                elif record['action'] == 'rejected':
                    status = 'rejected'
                
                formatted_proposals.append({
                    'proposal_id': record['history_id'],
                    'proposed_location': record['proposed_location'],
                    'proposed_latitude': _to_serializable(record['proposed_latitude']),
                    'proposed_longitude': _to_serializable(record['proposed_longitude']),
                    'proposed_time': proposed_time.isoformat() if proposed_time else None,
                    'message': record['notes'],
                    'status': status,
                    'action': record['action'],
                    'proposed_at': record['created_at'].isoformat() if record['created_at'] else None,
                    'is_from_me': record['proposed_by'] == user_id,
                    'proposer': {'first_name': record['FirstName'], 'last_name': record['LastName']}
                })
            
            # Check for accepted proposal
            cursor.execute("""
                SELECT nh.history_id, nh.action, nh.proposed_time, nh.proposed_location,
                       nh.proposed_latitude, nh.proposed_longitude, nh.proposed_by, nh.notes, nh.created_at,
                       u.FirstName, u.LastName
                FROM negotiation_history nh
                JOIN users u ON nh.proposed_by = u.user_id
                WHERE nh.negotiation_id = %s
                AND nh.action IN ('accepted_time', 'accepted_location')
                ORDER BY nh.created_at DESC
                LIMIT 1
            """, (negotiation_id,))
            accepted_record = cursor.fetchone()
            
            if accepted_record:
                accepted_time = accepted_record['proposed_time']
                if accepted_time and accepted_time.tzinfo is None:
                    accepted_time = accepted_time.replace(tzinfo=timezone.utc)
                
                current_meeting = {
                    'proposal_id': accepted_record['history_id'],
                    'location': accepted_record['proposed_location'],
                    'latitude': _to_serializable(accepted_record['proposed_latitude']),
                    'longitude': _to_serializable(accepted_record['proposed_longitude']),
                    'time': accepted_time.isoformat() if accepted_time else None,
                    'message': accepted_record['notes'],
                    'proposed_at': accepted_record['created_at'].isoformat() if accepted_record['created_at'] else None,
                    'agreed_at': accepted_record['created_at'].isoformat() if accepted_record['created_at'] else None,
                    'proposer': {'first_name': accepted_record['FirstName'], 'last_name': accepted_record['LastName']}
                }
                print(f"[GetMeetingProposals] Found accepted: {current_meeting['location']} @ {current_meeting['time']}")
        
        connection.close()
        
        print(f"[GetMeetingProposals] ===== END: {len(formatted_proposals)} proposals, meeting={current_meeting is not None} =====")
        
        return json.dumps({
            'success': True,
            'proposals': formatted_proposals,
            'current_meeting': current_meeting,
            'user_access_type': access_result['access_type']
        }, cls=DecimalEncoder)
        
    except Exception as e:
        print(f"[GetMeetingProposals] Error: {str(e)}")
        import traceback
        print(traceback.format_exc())
        return json.dumps({'success': False, 'error': f'Failed to get meeting proposals: {str(e)}'}, cls=DecimalEncoder)
