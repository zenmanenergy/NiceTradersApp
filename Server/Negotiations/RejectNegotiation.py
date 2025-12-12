import json
import uuid
from _Lib import Database

def reject_negotiation(listing_id, session_id):
    """
    Reject time negotiation (ends the negotiation)
    
    Args:
        listing_id: ID of the listing
        session_id: User's session ID
    
    Returns:
        JSON response confirming rejection
    """
    cursor, connection = Database.ConnectToDatabase()
    
    try:
        # Verify session and get user_id
        cursor.execute("SELECT user_id FROM usersessions WHERE SessionId = %s", (session_id,))
        session_result = cursor.fetchone()
        
        if not session_result:
            return json.dumps({
                'success': False,
                'error': 'Invalid or expired session'
            })
        
        user_id = session_result['user_id']
        
        # Get time negotiation for this listing
        cursor.execute("""
            SELECT time_negotiation_id, buyer_id, accepted_at, rejected_at
            FROM listing_meeting_time
            WHERE listing_id = %s
        """, (listing_id,))
        
        time_neg = cursor.fetchone()
        
        if not time_neg:
            return json.dumps({
                'success': False,
                'error': 'No time proposal found for this listing'
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
        if user_id != seller_id and user_id != time_neg['buyer_id']:
            return json.dumps({
                'success': False,
                'error': 'You do not have access to this negotiation'
            })
        
        # Check if already rejected or accepted
        if time_neg['rejected_at'] is not None:
            return json.dumps({
                'success': False,
                'error': 'This negotiation has already been rejected'
            })
        
        if time_neg['accepted_at'] is not None:
            return json.dumps({
                'success': False,
                'error': 'Cannot reject an accepted proposal'
            })
        
        # Reject the time negotiation
        cursor.execute("""
            UPDATE listing_meeting_time
            SET rejected_at = NOW(), updated_at = NOW()
            WHERE listing_id = %s
        """, (listing_id,))
        
        # Clear buyer_id in listings table
        cursor.execute("""
            UPDATE listings
            SET buyer_id = NULL
            WHERE listing_id = %s
        """, (listing_id,))
        
        connection.commit()
        
        print(f"[Negotiations] RejectNegotiation success: listing_id={listing_id}, user_id={user_id}")
        
        return json.dumps({
            'success': True,
            'status': 'rejected',
            'message': 'Negotiation rejected'
        })
        
    except Exception as e:
        try:
            connection.rollback()
        except:
            pass
        print(f"[Negotiations] RejectNegotiation error: {str(e)}")
        import traceback
        print(f"[Negotiations] Traceback: {traceback.format_exc()}")
        return json.dumps({
            'success': False,
            'error': 'Failed to reject negotiation'
        })
    
    finally:
        cursor.close()
        connection.close()
