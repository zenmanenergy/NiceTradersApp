from _Lib import Database
import json
from datetime import datetime

def get_purchased_contacts(session_id):
    """Get all listings that the user has purchased contact access to"""
    try:
        print(f"[GetPurchasedContacts] Getting purchased contacts for session {session_id}")
        
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
        
        # First check if exchange rate columns exist
        cursor.execute("DESCRIBE contact_access")
        columns = [row['Field'] for row in cursor.fetchall()]
        has_exchange_columns = 'exchange_rate' in columns
        
        # Get all purchased contacts with listing and seller details
        # Use ROW_NUMBER to get only the most recent access per listing
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
                    l.latitude,
                    l.longitude,
                    l.location_radius,
                    l.meeting_preference,
                    l.available_until,
                    l.will_round_to_nearest_dollar,
                    u.FirstName as seller_first_name,
                    u.LastName as seller_last_name,
                    u.Email as seller_email,
                    l.user_id as seller_user_id,
                    -- Get latest message info
                    (SELECT COUNT(*) FROM messages m WHERE m.listing_id = l.listing_id 
                     AND ((m.sender_id = %s AND m.recipient_id = l.user_id) 
                          OR (m.sender_id = l.user_id AND m.recipient_id = %s))) as message_count,
                    (SELECT m.message_text FROM messages m WHERE m.listing_id = l.listing_id
                     AND ((m.sender_id = %s AND m.recipient_id = l.user_id) 
                          OR (m.sender_id = l.user_id AND m.recipient_id = %s))
                     ORDER BY m.sent_at DESC LIMIT 1) as last_message,
                    (SELECT m.sent_at FROM messages m WHERE m.listing_id = l.listing_id
                     AND ((m.sender_id = %s AND m.recipient_id = l.user_id) 
                          OR (m.sender_id = l.user_id AND m.recipient_id = %s))
                     ORDER BY m.sent_at DESC LIMIT 1) as last_message_time
                FROM (
                    SELECT *,
                        ROW_NUMBER() OVER (PARTITION BY listing_id ORDER BY purchased_at DESC) as rn
                    FROM contact_access
                    WHERE user_id = %s 
                    AND status = 'active'
                    AND (expires_at IS NULL OR expires_at > NOW())
                ) ca
                JOIN listings l ON ca.listing_id = l.listing_id
                JOIN users u ON l.user_id = u.user_id
                WHERE ca.rn = 1
                ORDER BY ca.purchased_at DESC
            """
        else:
            # Fallback query without exchange rate columns
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
                    l.latitude,
                    l.longitude,
                    l.location_radius,
                    l.meeting_preference,
                    l.available_until,
                    l.will_round_to_nearest_dollar,
                    u.FirstName as seller_first_name,
                    u.LastName as seller_last_name,
                    u.Email as seller_email,
                    l.user_id as seller_user_id,
                    -- Get latest message info
                    (SELECT COUNT(*) FROM messages m WHERE m.listing_id = l.listing_id 
                     AND ((m.sender_id = %s AND m.recipient_id = l.user_id) 
                          OR (m.sender_id = l.user_id AND m.recipient_id = %s))) as message_count,
                    (SELECT m.message_text FROM messages m WHERE m.listing_id = l.listing_id
                     AND ((m.sender_id = %s AND m.recipient_id = l.user_id) 
                          OR (m.sender_id = l.user_id AND m.recipient_id = %s))
                     ORDER BY m.sent_at DESC LIMIT 1) as last_message,
                    (SELECT m.sent_at FROM messages m WHERE m.listing_id = l.listing_id
                     AND ((m.sender_id = %s AND m.recipient_id = l.user_id) 
                          OR (m.sender_id = l.user_id AND m.recipient_id = %s))
                     ORDER BY m.sent_at DESC LIMIT 1) as last_message_time
                FROM (
                    SELECT *,
                        ROW_NUMBER() OVER (PARTITION BY listing_id ORDER BY purchased_at DESC) as rn
                    FROM contact_access
                    WHERE user_id = %s 
                    AND status = 'active'
                    AND (expires_at IS NULL OR expires_at > NOW())
                ) ca
                JOIN listings l ON ca.listing_id = l.listing_id AND ca.user_id != l.user_id
                JOIN users u ON l.user_id = u.user_id
                WHERE ca.rn = 1
                ORDER BY ca.purchased_at DESC
            """
        
        cursor.execute(query, (user_id, user_id, user_id, user_id, user_id, user_id, user_id))
        results = cursor.fetchall()
        
        purchased_contacts = []
        for row in results:
            contact = {
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
                    'latitude': float(row['latitude']) if row['latitude'] else 0.0,
                    'longitude': float(row['longitude']) if row['longitude'] else 0.0,
                    'location_radius': int(row['location_radius']) if row['location_radius'] else 5,
                    'meeting_preference': row['meeting_preference'],
                    'available_until': row['available_until'].isoformat() if row['available_until'] else None,
                    'will_round_to_nearest_dollar': row['will_round_to_nearest_dollar']
                },
                'seller': {
                    'user_id': row['seller_user_id'],
                    'name': f"{row['seller_first_name']} {row['seller_last_name']}",
                    'email': row['seller_email']
                },
                'conversation': {
                    'message_count': int(row['message_count']) if row['message_count'] else 0,
                    'last_message': row['last_message'],
                    'last_message_time': row['last_message_time'].isoformat() if row['last_message_time'] else None
                }
            }
            purchased_contacts.append(contact)
        
        connection.close()
        
        return json.dumps({
            'success': True,
            'purchased_contacts': purchased_contacts,
            'total': len(purchased_contacts)
        })
        
    except Exception as e:
        print(f"[GetPurchasedContacts] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': 'Failed to retrieve purchased contacts'
        })