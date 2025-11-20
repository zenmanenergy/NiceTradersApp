from _Lib import Database
import json
import uuid
from datetime import datetime

def send_contact_message(session_id, listing_id, message_text):
    """Send a message in a contact conversation"""
    try:
        print(f"[SendContactMessage] Sending message for session {session_id}, listing {listing_id}")
        
        if not message_text or not message_text.strip():
            return json.dumps({
                'success': False,
                'error': 'Message text is required'
            })
        
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
        
        # Verify user has access to this conversation and determine recipient
        access_query = """
            SELECT 
                l.user_id as listing_owner_id,
                ca.user_id as purchaser_id
            FROM listings l
            LEFT JOIN contact_access ca ON l.listing_id = ca.listing_id 
                AND ca.status = 'active' 
                AND (ca.expires_at IS NULL OR ca.expires_at > NOW())
            WHERE l.listing_id = %s
            AND (l.user_id = %s OR ca.user_id = %s)
        """
        
        cursor.execute(access_query, (listing_id, user_id, user_id))
        access_result = cursor.fetchone()
        
        if not access_result:
            return json.dumps({
                'success': False,
                'error': 'Access denied - you must purchase contact access or own this listing'
            })
        
        listing_owner_id = access_result['listing_owner_id']
        purchaser_id = access_result['purchaser_id']
        
        # Determine recipient
        if user_id == listing_owner_id:
            recipient_id = purchaser_id
        else:
            recipient_id = listing_owner_id
        
        if not recipient_id:
            return json.dumps({
                'success': False,
                'error': 'No valid recipient found for this conversation'
            })
        
        # Insert the message
        message_id = str(uuid.uuid4())
        sent_at = datetime.now()
        
        cursor.execute("""
            INSERT INTO messages (
                message_id, listing_id, sender_id, recipient_id, 
                message_text, sent_at, read_at
            ) VALUES (%s, %s, %s, %s, %s, %s, NULL)
        """, (message_id, listing_id, user_id, recipient_id, message_text.strip(), sent_at))
        
        # Create notification for recipient
        notification_id = str(uuid.uuid4())
        cursor.execute("""
            INSERT INTO notifications (
                notification_id, user_id, type, title, message, 
                related_id, created_at, read_at
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, NULL)
        """, (
            notification_id, 
            recipient_id, 
            'new_message',
            'New Message',
            f'You have a new message about your listing',
            listing_id,
            sent_at
        ))
        
        connection.commit()
        connection.close()
        
        return json.dumps({
            'success': True,
            'message_id': message_id,
            'sent_at': sent_at.isoformat(),
            'message': 'Message sent successfully'
        })
        
    except Exception as e:
        print(f"[SendContactMessage] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': 'Failed to send message'
        })