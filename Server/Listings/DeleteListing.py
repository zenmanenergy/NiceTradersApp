from _Lib import Database
import json

def delete_listing(SessionId, ListingId, Permanent):
    """Delete or deactivate a listing"""
    try:
        session_id = SessionId
        listing_id = ListingId
        permanent = (Permanent or 'false').lower() == 'true'
        
        print(f"[DeleteListing] {'Permanently deleting' if permanent else 'Deactivating'} listing: {listing_id}")
        
        if not all([session_id, listing_id]):
            return json.dumps({
                'success': False,
                'error': 'Session ID and Listing ID are required'
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
        
        # Verify user owns the listing
        ownership_query = """
            SELECT user_id FROM listings WHERE listing_id = %s
        """
        cursor.execute(ownership_query, (listing_id,))
        ownership_result = cursor.fetchone()
        
        if not ownership_result or ownership_result['user_id'] != user_id:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'You can only delete your own listings'
            })
        
        if permanent:
            # Permanently delete from database
            delete_query = "DELETE FROM listings WHERE listing_id = %s"
            cursor.execute(delete_query, (listing_id,))
            message = 'Listing permanently deleted'
        else:
            # Soft delete - mark as inactive
            update_query = """
                UPDATE listings 
                SET status = 'inactive', updated_at = NOW() 
                WHERE listing_id = %s
            """
            cursor.execute(update_query, (listing_id,))
            message = 'Listing deactivated'
        
        connection.commit()
        connection.close()
        
        print(f"[DeleteListing] Successfully processed listing {listing_id}")
        
        return json.dumps({
            'success': True,
            'message': message
        })
        
    except Exception as e:
        print(f"[DeleteListing] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': 'Failed to delete listing'
        })