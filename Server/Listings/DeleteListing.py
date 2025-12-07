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
        
        # Check if there are any paid negotiations for this listing
        paid_check_query = """
            SELECT COUNT(DISTINCT negotiation_id) as paid_count 
            FROM negotiation_history 
            WHERE listing_id = %s 
            AND action IN ('buyer_paid', 'seller_paid')
            AND (SELECT COUNT(*) FROM negotiation_history nh2 
                 WHERE nh2.negotiation_id = negotiation_history.negotiation_id 
                 AND nh2.action IN ('buyer_paid', 'seller_paid')) >= 2
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
            SELECT DISTINCT proposed_by FROM negotiation_history 
            WHERE listing_id = %s 
            AND action IN ('time_proposal', 'location_proposal', 'counter_proposal')
            AND proposed_by != %s
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
            seller_query = "SELECT first_name, last_name FROM users WHERE UserID = %s"
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