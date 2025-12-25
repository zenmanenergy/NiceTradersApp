"""
CancelMeetingTime.py - Clear the accepted_at timestamp for meeting time
Removes the accepted time but keeps the proposal history
"""

import pymysql
from _Lib.Database import ConnectToDatabase

def cancel_meeting_time(session_id, listing_id):
    """
    Cancel the accepted meeting time by clearing the accepted_at timestamp
    
    Args:
        session_id: Session ID for authorization
        listing_id: Listing ID to cancel time for
        
    Returns:
        Dictionary with success status and message
    """
    
    db = None
    cursor = None
    
    try:
        # Verify user has access to this listing
        cursor, db = ConnectToDatabase()
        
        # Get the user ID from session
        cursor.execute(
            "SELECT user_id FROM user_sessions WHERE session_id = %s",
            (session_id,)
        )
        result = cursor.fetchone()
        if not result:
            return {"success": False, "message": "Invalid session"}
        
        user_id = result['user_id']
        
        # Verify user owns this listing or is involved in negotiation
        cursor.execute(
            """SELECT l.user_id, lmt.buyer_id FROM listings l
               LEFT JOIN listing_meeting_time lmt ON l.listing_id = lmt.listing_id
               WHERE l.listing_id = %s""",
            (listing_id,)
        )
        result = cursor.fetchone()
        if not result:
            return {"success": False, "message": "Listing not found"}
        
        seller_id = result['user_id']
        buyer_id = result['buyer_id']
        if user_id not in (seller_id, buyer_id):
            return {"success": False, "message": "Unauthorized"}
        
        # Clear the accepted_at timestamp for the meeting time
        cursor.execute(
            """UPDATE listing_meeting_time 
               SET accepted_at = NULL, updated_at = NOW()
               WHERE listing_id = %s""",
            (listing_id,)
        )
        
        db.commit()
        
        print(f"[CancelMeetingTime] Successfully cleared meeting time for listing {listing_id}")
        
        return {
            "success": True,
            "message": "Meeting time cancelled"
        }
        
    except Exception as e:
        print(f"[CancelMeetingTime] Error: {str(e)}")
        import traceback
        traceback.print_exc()
        return {"success": False, "message": f"Error: {str(e)}"}
    finally:
        if cursor:
            cursor.close()
        if db:
            db.close()
