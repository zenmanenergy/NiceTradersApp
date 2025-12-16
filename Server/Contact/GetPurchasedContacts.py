from _Lib import Database
import json
from datetime import datetime
import sys
sys.path.insert(0, '/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server')
from Dashboard.GetUserDashboard import calculate_negotiation_status

def get_purchased_contacts(session_id):
    """Get all listings that the user has active negotiations for (as buyer)"""
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
        
        # Get all active negotiations where current user is the buyer
        # Based on listing_meeting_time where buyer_id matches current user
        query = """
            SELECT 
                lmt.listing_id,
                lmt.buyer_id,
                lmt.proposed_by,
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
                lmt.meeting_time,
                lmt.accepted_at,
                lmt.rejected_at,
                lp.buyer_paid_at,
                lp.seller_paid_at,
                CASE WHEN lml.location_negotiation_id IS NOT NULL THEN 1 ELSE 0 END as has_location_proposal,
                lml.proposed_by as location_proposed_by,
                lml.accepted_at as location_accepted_at,
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
            FROM listing_meeting_time lmt
            JOIN listings l ON lmt.listing_id = l.listing_id
            JOIN users u ON l.user_id = u.user_id
            LEFT JOIN listing_payments lp ON l.listing_id = lp.listing_id
            LEFT JOIN listing_meeting_location lml ON l.listing_id = lml.listing_id
            WHERE lmt.buyer_id = %s
            AND lmt.rejected_at IS NULL
            AND l.status != 'completed'
            ORDER BY lmt.updated_at DESC
        """
        
        cursor.execute(query, (user_id, user_id, user_id, user_id, user_id, user_id, user_id))
        results = cursor.fetchall()
        
        purchased_contacts = []
        for row in results:
            # Calculate displayStatus for the exchange
            display_status = calculate_negotiation_status(row, user_id)
            
            contact = {
                'listing_id': row['listing_id'],
                'meeting_time': row['meeting_time'].isoformat() if row['meeting_time'] else None,
                'accepted_at': row['accepted_at'].isoformat() if row['accepted_at'] else None,
                'rejected_at': row['rejected_at'].isoformat() if row['rejected_at'] else None,
                'buyer_paid_at': row['buyer_paid_at'].isoformat() if row['buyer_paid_at'] else None,
                'seller_paid_at': row['seller_paid_at'].isoformat() if row['seller_paid_at'] else None,
                'displayStatus': display_status,
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