from _Lib import Database
import json
from datetime import datetime

def get_contact_messages(session_id, listing_id):
    """Get all messages for a specific listing contact between buyer and seller"""
    try:
        print(f"[GetContactMessages] Getting messages for session {session_id}, listing {listing_id}")
        
        # Connect to database
        cursor, connection = Database.ConnectToDatabase()
        
        # First, get user_id from session_id
        cursor.execute("SELECT user_id FROM usersessions WHERE SessionId = %s", (session_id,))
        session_result = cursor.fetchone()
        
        if not session_result:
            return json.dumps({
                'success': False,
                'error': 'Invalid or expired session'
            })
        
        user_id = session_result['user_id']
        
        # Verify user has access to this conversation (either listing owner or buyer with active negotiation)
        access_query = """
            SELECT 
                l.user_id as listing_owner_id,
                lmt.buyer_id as buyer_id,
                l.currency,
                l.amount,
                l.accept_currency,
                l.location
            FROM listings l
            LEFT JOIN listing_meeting_time lmt ON l.listing_id = lmt.listing_id 
                AND lmt.rejected_at IS NULL
            WHERE l.listing_id = %s
            AND (l.user_id = %s OR lmt.buyer_id = %s)
        """
        
        cursor.execute(access_query, (listing_id, user_id, user_id))
        access_result = cursor.fetchone()
        
        if not access_result:
            return json.dumps({
                'success': False,
                'error': 'Access denied - you must have an active negotiation or own this listing'
            })
        
        listing_owner_id = access_result['listing_owner_id']
        buyer_id = access_result['buyer_id']
        
        # Determine the other participant in the conversation
        if user_id == listing_owner_id:
            other_user_id = buyer_id
            user_role = 'seller'
        else:
            other_user_id = listing_owner_id  
            user_role = 'buyer'
        
        # Get listing details
        listing_info = {
            'currency': access_result['currency'],
            'amount': float(access_result['amount']) if access_result['amount'] else 0,
            'accept_currency': access_result['accept_currency'],
            'location': access_result['location']
        }
        
        # Get other user details
        cursor.execute("SELECT FirstName, LastName, Email FROM users WHERE user_id = %s", (other_user_id,))
        other_user_result = cursor.fetchone()
        
        other_user_info = {
            'user_id': other_user_id,
            'name': f"{other_user_result['FirstName']} {other_user_result['LastName']}" if other_user_result else 'Unknown User',
            'email': other_user_result['Email'] if other_user_result else ''
        }
        
        # Get all messages between the participants for this listing
        messages_query = """
            SELECT 
                m.message_id,
                m.message_text,
                m.sent_at,
                m.read_at,
                m.sender_id,
                m.recipient_id,
                sender.FirstName as sender_first_name,
                sender.LastName as sender_last_name,
                recipient.FirstName as recipient_first_name,
                recipient.LastName as recipient_last_name
            FROM messages m
            JOIN users sender ON m.sender_id = sender.user_id
            JOIN users recipient ON m.recipient_id = recipient.user_id
            WHERE m.listing_id = %s
            AND ((m.sender_id = %s AND m.recipient_id = %s) 
                 OR (m.sender_id = %s AND m.recipient_id = %s))
            ORDER BY m.sent_at ASC
        """
        
        cursor.execute(messages_query, (listing_id, user_id, other_user_id, other_user_id, user_id))
        message_results = cursor.fetchall()
        
        messages = []
        for row in message_results:
            message = {
                'message_id': row['message_id'],
                'message_text': row['message_text'],
                'sent_at': row['sent_at'].isoformat() if row['sent_at'] else None,
                'read_at': row['read_at'].isoformat() if row['read_at'] else None,
                'sender_id': row['sender_id'],
                'recipient_id': row['recipient_id'],
                'sender_name': f"{row['sender_first_name']} {row['sender_last_name']}",
                'recipient_name': f"{row['recipient_first_name']} {row['recipient_last_name']}",
                'is_from_user': row['sender_id'] == user_id
            }
            messages.append(message)
        
        # Mark messages as read that were sent to current user
        cursor.execute("""
            UPDATE messages 
            SET read_at = NOW() 
            WHERE listing_id = %s 
            AND recipient_id = %s 
            AND sender_id = %s 
            AND read_at IS NULL
        """, (listing_id, user_id, other_user_id))
        
        connection.commit()
        connection.close()
        
        return json.dumps({
            'success': True,
            'listing_id': listing_id,
            'user_role': user_role,
            'listing': listing_info,
            'other_user': other_user_info,
            'messages': messages,
            'total_messages': len(messages)
        })
        
    except Exception as e:
        print(f"[GetContactMessages] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': 'Failed to retrieve messages'
        })