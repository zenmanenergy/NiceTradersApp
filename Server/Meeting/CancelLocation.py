"""
CancelLocation.py - Delete the meeting location acceptance
Removes the accepted location proposal but keeps history
"""

import pymysql
from _Lib.Database import Database

def cancel_location(session_id, listing_id):
    """
    Cancel the accepted meeting location by clearing the acceptance
    
    Args:
        session_id: Session ID for authorization
        listing_id: Listing ID to cancel location for
        
    Returns:
        Dictionary with success status and message
    """
    
    try:
        # Verify user has access to this listing
        db = Database.get_connection()
        cursor = db.cursor()
        
        # Get the user ID from session
        cursor.execute(
            "SELECT user_id FROM usersessions WHERE session_id = %s",
            (session_id,)
        )
        result = cursor.fetchone()
        if not result:
            return {"success": False, "message": "Invalid session"}
        
        user_id = result[0]
        
        # Verify user owns this listing or is the other party
        cursor.execute(
            """SELECT seller_id, buyer_id FROM listings WHERE listing_id = %s""",
            (listing_id,)
        )
        result = cursor.fetchone()
        if not result:
            return {"success": False, "message": "Listing not found"}
        
        seller_id, buyer_id = result
        if user_id not in (seller_id, buyer_id):
            return {"success": False, "message": "Unauthorized"}
        
        # Clear the accepted_at timestamp for the meeting location
        cursor.execute(
            """UPDATE listing_meeting_location 
               SET accepted_at = NULL
               WHERE listing_id = %s""",
            (listing_id,)
        )
        
        db.commit()
        
        print(f"[CancelLocation] Successfully cleared meeting location for listing {listing_id}")
        
        return {
            "success": True,
            "message": "Meeting location cancelled"
        }
        
    except Exception as e:
        print(f"[CancelLocation] Error: {str(e)}")
        return {"success": False, "message": f"Error: {str(e)}"}
    finally:
        if cursor:
            cursor.close()
        if db:
            db.close()
