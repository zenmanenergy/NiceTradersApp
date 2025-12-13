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
            SELECT user_id FROM usersessions 
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
        
        user_id = session_result['user_id']
        
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
        
        # Check if there are any paid negotiations for this listing
        paid_check_query = """
            SELECT COUNT(*) as paid_count 
            FROM listing_payments 
            WHERE listing_id = %s 
            AND buyer_paid_at IS NOT NULL
            AND seller_paid_at IS NOT NULL
        """
        cursor.execute(paid_check_query, (listing_id,))
        paid_result = cursor.fetchone()
        
        if paid_result and paid_result['paid_count'] > 0:
            connection.close()
            return json.dumps({
                'success': False,
                'error': 'Cannot delete listing - a buyer has already paid for this exchange'
            })
        
        # Get all negotiating/pending buyers to notify them
        notify_query = """
            SELECT DISTINCT lmt.buyer_id FROM listing_meeting_time lmt
            WHERE lmt.listing_id = %s 
            AND lmt.buyer_id != %s
        """
        cursor.execute(notify_query, (listing_id, user_id))
        buyers_to_notify = cursor.fetchall()
        
        # Get listing and seller information for notification
        listing_query = """
            SELECT title, description, seller_id FROM listings 
            WHERE listing_id = %s
        """
        cursor.execute(listing_query, (listing_id,))
        listing_info = cursor.fetchone()
        
        if listing_info:
            listing_title = listing_info[0]
            seller_id = listing_info[2]
            
            # Get seller name
            seller_query = "SELECT first_name, last_name FROM users WHERE user_id = %s"
            cursor.execute(seller_query, (seller_id,))
            seller = cursor.fetchone()
            seller_name = f"{seller[0]} {seller[1]}" if seller else "Seller"
            
            # TODO: Send notifications to affected buyers when notification service is available
            # for buyer in buyers_to_notify:
            #     buyer_id = buyer[0]
            #     try:
            #         send_buyer_notification(...)
            #     except Exception as notification_error:
            #         print(f"[DeleteListing] Warning: Failed to send notification")
        
        if permanent:
            # Permanently delete from database
            delete_query = "DELETE FROM listings WHERE listing_id = %s"
            cursor.execute(delete_query, (listing_id,))
            # Also delete associated meeting time proposals
            cursor.execute("DELETE FROM listing_meeting_time WHERE listing_id = %s", (listing_id,))
            # Also delete associated meeting location proposals
            cursor.execute("DELETE FROM listing_meeting_location WHERE listing_id = %s", (listing_id,))
            message = 'Listing permanently deleted'
        else:
            # Soft delete - mark as inactive and delete proposals
            update_query = """
                UPDATE listings 
                SET status = 'inactive', updated_at = NOW() 
                WHERE listing_id = %s
            """
            cursor.execute(update_query, (listing_id,))
            # Also delete associated proposals when listing is deactivated
            cursor.execute("DELETE FROM listing_meeting_time WHERE listing_id = %s", (listing_id,))
            cursor.execute("DELETE FROM listing_meeting_location WHERE listing_id = %s", (listing_id,))
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