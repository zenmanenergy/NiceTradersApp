from _Lib import Database
import json
from datetime import datetime
import uuid

def send_interest_message(listing_id, session_id, message='', availability=[]):
    """Send interest message to a trader with availability preferences"""
    try:
        print(f"[SendInterestMessage] Sending message for listing {listing_id}, session {session_id}")
        
        # Connect to database
        cursor, connection = Database.ConnectToDatabase()
        
        # First, get user_id from session_id
        cursor.execute("SELECT UserId FROM usersessions WHERE SessionId = %s", (session_id,))
        session_result = cursor.fetchone()
        
        if not session_result:
            return json.dumps({
                'success': False,
                'error': 'Invalid or expired session'
            })
        
        user_id = session_result['UserId']
        
        # Get listing details and owner
        cursor.execute("""
            SELECT user_id, currency, amount, status FROM listings 
            WHERE listing_id = %s
        """, (listing_id,))
        
        listing_result = cursor.fetchone()
        if not listing_result:
            return json.dumps({
                'success': False,
                'error': 'Listing not found'
            })
        
        listing_owner_id = listing_result['user_id']
        listing_status = listing_result['status']
        
        if listing_status != 'active':
            return json.dumps({
                'success': False,
                'error': 'Listing is no longer active'
            })
        
        # Check if user is trying to message their own listing
        if listing_owner_id == user_id:
            return json.dumps({
                'success': False,
                'error': 'Cannot send interest message to your own listing'
            })
        
        # Check if user has contact access (required to send messages)
        cursor.execute("""
            SELECT access_id FROM contact_access 
            WHERE user_id = %s AND listing_id = %s AND status = 'active'
            AND (expires_at IS NULL OR expires_at > NOW())
        """, (user_id, listing_id))
        
        access_result = cursor.fetchone()
        if not access_result:
            return json.dumps({
                'success': False,
                'error': 'You must purchase contact access before sending messages'
            })
        
        # Create the interest message
        message_id = str(uuid.uuid4())
        created_at = datetime.now()
        
        # Format availability as JSON string
        availability_json = json.dumps(availability) if availability else None
        
        message_query = """
            INSERT INTO messages (
                message_id, listing_id, sender_id, recipient_id, 
                message_type, message_content, availability_preferences,
                status, created_at
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        """
        
        cursor.execute(message_query, (
            message_id, listing_id, user_id, listing_owner_id,
            'interest', message, availability_json, 'sent', created_at
        ))
        
        # Update listing to track interest count
        cursor.execute("""
            UPDATE listings 
            SET interest_count = COALESCE(interest_count, 0) + 1,
                last_interest_at = %s
            WHERE listing_id = %s
        """, (created_at, listing_id))
        
        # Create notification for listing owner
        notification_id = str(uuid.uuid4())
        notification_query = """
            INSERT INTO notifications (
                notification_id, user_id, type, title, message,
                related_id, status, created_at
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """
        
        # Get sender name for notification
        cursor.execute("SELECT FirstName, LastName FROM users WHERE UserId = %s", (user_id,))
        sender_result = cursor.fetchone()
        sender_name = f"{sender_result['FirstName']} {sender_result['LastName']}" if sender_result else "Someone"
        
        notification_title = "New Interest in Your Listing"
        notification_message = f"{sender_name} has expressed interest in your {listing_result['currency']} {listing_result['amount']} listing"
        
        cursor.execute(notification_query, (
            notification_id, listing_owner_id, 'new_interest', notification_title,
            notification_message, listing_id, 'unread', created_at
        ))
        
        # Commit the transaction
        connection.commit()
        
        response_data = {
            'success': True,
            'message': 'Interest message sent successfully',
            'message_details': {
                'message_id': message_id,
                'sent_at': created_at.isoformat(),
                'availability_preferences': availability,
                'status': 'sent'
            }
        }
        
        # Close database connection
        cursor.close()
        connection.close()
        
        return json.dumps(response_data)
        
    except Exception as e:
        print(f"[SendInterestMessage] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': 'Failed to send interest message'
        })