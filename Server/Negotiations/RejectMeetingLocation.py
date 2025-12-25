import json
import uuid
from datetime import datetime
from _Lib import Database

def reject_meeting_location(listing_id, session_id):
    """
    Reject the current location proposal
    
    Args:
        listing_id: ID of the listing
        session_id: User's session ID
    
    Returns:
        JSON response confirming rejection
    """
    cursor, connection = Database.ConnectToDatabase()
    
    try:
        # Verify session and get user_id
        cursor.execute("SELECT user_id FROM user_sessions WHERE session_id = %s", (session_id,))
        session_result = cursor.fetchone()
        
        if not session_result:
            return json.dumps({
                'success': False,
                'error': 'Invalid or expired session'
            })
        
        user_id = session_result['user_id']
        
        # Get location negotiation for this listing
        cursor.execute("""
            SELECT location_negotiation_id, buyer_id, accepted_at, rejected_at
            FROM listing_meeting_location
            WHERE listing_id = %s
        """, (listing_id,))
        
        location_neg = cursor.fetchone()
        
        if not location_neg:
            return json.dumps({
                'success': False,
                'error': 'No location proposal found for this listing'
            })
        
        # Check if already rejected or accepted
        if location_neg['rejected_at'] is not None:
            return json.dumps({
                'success': False,
                'error': 'This location proposal has already been rejected'
            })
        
        if location_neg['accepted_at'] is not None:
            return json.dumps({
                'success': False,
                'error': 'Cannot reject an accepted proposal'
            })
        
        # Get listing info
        cursor.execute("""
            SELECT user_id FROM listings WHERE listing_id = %s
        """, (listing_id,))
        
        listing = cursor.fetchone()
        if not listing:
            return json.dumps({
                'success': False,
                'error': 'Listing not found'
            })
        
        seller_id = listing['user_id']
        
        # Verify user is part of this negotiation
        if user_id != seller_id and user_id != location_neg['buyer_id']:
            return json.dumps({
                'success': False,
                'error': 'You do not have access to this negotiation'
            })
        
        # Reject the location negotiation
        cursor.execute("""
            UPDATE listing_meeting_location
            SET rejected_at = NOW(), updated_at = NOW()
            WHERE listing_id = %s
        """, (listing_id,))
        
        connection.commit()
        
        print(f"[Negotiations] RejectMeetingLocation success: listing_id={listing_id}, user_id={user_id}")
        
        return json.dumps({
            'success': True,
            'status': 'rejected',
            'message': 'Location proposal rejected'
        })
        
    except Exception as e:
        try:
            connection.rollback()
        except:
            pass
        print(f"[Negotiations] RejectMeetingLocation error: {str(e)}")
        import traceback
        print(f"[Negotiations] Traceback: {traceback.format_exc()}")
        return json.dumps({
            'success': False,
            'error': 'Failed to reject location proposal'
        })
    
    finally:
        cursor.close()
        connection.close()
