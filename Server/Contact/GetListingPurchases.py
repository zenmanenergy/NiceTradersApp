from _Lib import Database
import json
from datetime import datetime

def get_listing_purchases(session_id):
    """Get all purchases made for the user's listings (for listing owners)"""
    try:
        print(f"[GetListingPurchases] Getting listing purchases for session {session_id}")
        
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
        
        # First check if exchange rate columns exist
        cursor.execute("DESCRIBE contact_access")
        columns = [row['Field'] for row in cursor.fetchall()]
        has_exchange_columns = 'exchange_rate' in columns
        
        # Get all purchases for user's listings with buyer details
        if has_exchange_columns:
            query = """
                SELECT 
                    ca.access_id,
                    ca.listing_id,
                    ca.purchased_at,
                    ca.expires_at,
                    ca.transaction_id,
                    ca.exchange_rate,
                    ca.locked_amount,
                    ca.from_currency,
                    ca.to_currency,
                    ca.rate_calculation_date,
                    l.currency,
                    l.amount,
                    l.accept_currency,
                    l.location,
                    l.meeting_preference,
                    l.available_until,
                    u.FirstName as buyer_first_name,
                    u.LastName as buyer_last_name,
                    u.Email as buyer_email,
                    ca.user_id as buyer_user_id,
        """
        else:
            query = """
                SELECT 
                    ca.access_id,
                    ca.listing_id,
                    ca.purchased_at,
                    ca.expires_at,
                    ca.transaction_id,
                    NULL as exchange_rate,
                    NULL as locked_amount,
                    NULL as from_currency,
                    NULL as to_currency,
                    NULL as rate_calculation_date,
                    l.currency,
                    l.amount,
                    l.accept_currency,
                    l.location,
                    l.meeting_preference,
                    l.available_until,
                    u.FirstName as buyer_first_name,
                    u.LastName as buyer_last_name,
                    u.Email as buyer_email,
                    ca.user_id as buyer_user_id,
                -- Get latest message info
                (SELECT COUNT(*) FROM messages m WHERE m.listing_id = l.listing_id 
                 AND ((m.sender_id = %s AND m.recipient_id = ca.user_id) 
                      OR (m.sender_id = ca.user_id AND m.recipient_id = %s))) as message_count,
                (SELECT m.message_text FROM messages m WHERE m.listing_id = l.listing_id
                 AND ((m.sender_id = %s AND m.recipient_id = ca.user_id) 
                      OR (m.sender_id = ca.user_id AND m.recipient_id = %s))
                 ORDER BY m.sent_at DESC LIMIT 1) as last_message,
                (SELECT m.sent_at FROM messages m WHERE m.listing_id = l.listing_id
                 AND ((m.sender_id = %s AND m.recipient_id = ca.user_id) 
                      OR (m.sender_id = ca.user_id AND m.recipient_id = %s))
                 ORDER BY m.sent_at DESC LIMIT 1) as last_message_time
            FROM contact_access ca
            JOIN listings l ON ca.listing_id = l.listing_id
            JOIN users u ON ca.user_id = u.UserId
            WHERE l.user_id = %s 
            AND ca.status = 'active'
            AND (ca.expires_at IS NULL OR ca.expires_at > NOW())
            ORDER BY ca.purchased_at DESC
        """
        
        cursor.execute(query, (user_id, user_id, user_id, user_id, user_id, user_id, user_id))
        results = cursor.fetchall()
        
        listing_purchases = []
        for row in results:
            purchase = {
                'access_id': row['access_id'],
                'listing_id': row['listing_id'],
                'purchased_at': row['purchased_at'].isoformat() if row['purchased_at'] else None,
                'expires_at': row['expires_at'].isoformat() if row['expires_at'] else None,
                'transaction_id': row['transaction_id'],
                'exchange_rate': float(row['exchange_rate']) if row['exchange_rate'] else None,
                'locked_amount': float(row['locked_amount']) if row['locked_amount'] else None,
                'from_currency': row['from_currency'],
                'to_currency': row['to_currency'],
                'rate_calculation_date': row['rate_calculation_date'].isoformat() if row['rate_calculation_date'] else None,
                'listing': {
                    'currency': row['currency'],
                    'amount': float(row['amount']) if row['amount'] else 0,
                    'accept_currency': row['accept_currency'],
                    'location': row['location'],
                    'meeting_preference': row['meeting_preference'],
                    'available_until': row['available_until'].isoformat() if row['available_until'] else None
                },
                'buyer': {
                    'user_id': row['buyer_user_id'],
                    'name': f"{row['buyer_first_name']} {row['buyer_last_name']}",
                    'email': row['buyer_email']
                },
                'conversation': {
                    'message_count': int(row['message_count']) if row['message_count'] else 0,
                    'last_message': row['last_message'],
                    'last_message_time': row['last_message_time'].isoformat() if row['last_message_time'] else None
                }
            }
            listing_purchases.append(purchase)
        
        connection.close()
        
        return json.dumps({
            'success': True,
            'listing_purchases': listing_purchases,
            'total': len(listing_purchases)
        })
        
    except Exception as e:
        print(f"[GetListingPurchases] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': 'Failed to retrieve listing purchases'
        })