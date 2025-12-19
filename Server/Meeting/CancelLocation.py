"""
CancelLocation.py - Delete the meeting location proposal
Completely removes the location proposal from the database
"""

import pymysql
from _Lib.Database import ConnectToDatabase

def cancel_location(session_id, listing_id):
    """
    Cancel and delete the meeting location proposal
    
    Args:
        session_id: Session ID for authorization
        listing_id: Listing ID to cancel location for
        
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
            "SELECT user_id FROM usersessions WHERE SessionId = %s",
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
        
        # Delete the meeting location proposal entirely
        cursor.execute(
            """DELETE FROM listing_meeting_location 
               WHERE listing_id = %s""",
            (listing_id,)
        )
        
        db.commit()
        
        print(f"[CancelLocation] Successfully deleted meeting location for listing {listing_id}")
        
        return {
            "success": True,
            "message": "Meeting location cancelled"
        }
        
    except Exception as e:
        print(f"[CancelLocation] Error: {str(e)}")
        import traceback
        traceback.print_exc()
        return {"success": False, "message": f"Error: {str(e)}"}
    finally:
        if cursor:
            cursor.close()
        if db:
            db.close()
