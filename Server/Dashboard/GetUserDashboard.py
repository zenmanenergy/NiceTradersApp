from _Lib import Database
import json
from datetime import datetime
from decimal import Decimal

def get_user_dashboard(SessionId):
    """Get dashboard data for authenticated user"""
    try:
        session_id = SessionId
        
        print(f"[GetUserDashboard] Getting dashboard data for session: {session_id}")
        
        if not session_id:
            return json.dumps({
                'success': False,
                'error': 'Session ID is required'
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
        
        # Get user profile information
        user_query = """
            SELECT UserId, FirstName, LastName, Email, Phone, UserType, DateCreated, IsActive
            FROM users 
            WHERE UserId = %s
        """
        cursor.execute(user_query, (user_id,))
        user_data = cursor.fetchone()
        
        # Get user's active listings count (listings created by user as seller)
        active_listings_query = """
            SELECT COUNT(*) as count 
            FROM listings l
            WHERE l.user_id = %s 
            AND l.status = 'active'
            AND l.available_until > NOW()
        """
        cursor.execute(active_listings_query, (user_id,))
        active_listings_count = cursor.fetchone()['count']
        
        # Get active exchanges count (listings user is actively negotiating on as buyer or seller)
        active_exchanges_query = """
            SELECT COUNT(DISTINCT lmt.listing_id) as count
            FROM listing_meeting_time lmt
            JOIN listings l ON lmt.listing_id = l.listing_id
            WHERE (lmt.buyer_id = %s OR l.user_id = %s)
            AND l.status = 'active'
            AND l.available_until > NOW()
            AND lmt.rejected_at IS NULL
        """
        cursor.execute(active_exchanges_query, (user_id, user_id))
        active_exchanges_count = cursor.fetchone()['count']
        
        # Placeholder for completed transactions count (no transaction table yet)
        completed_transactions_count = 0
        
        # Get user's active listings (last 10 listings created by user as seller)
        user_listings_query = """
            SELECT l.listing_id, l.currency, l.amount, l.accept_currency, l.location, 
                   l.status, l.created_at, l.available_until, l.will_round_to_nearest_dollar
            FROM listings l
            WHERE l.user_id = %s 
            AND l.status = 'active'
            AND l.available_until > NOW()
            ORDER BY l.created_at DESC 
            LIMIT 10
        """
        cursor.execute(user_listings_query, (user_id,))
        user_listings = cursor.fetchall()
        
        # Get user's active exchanges (listings user is negotiating on as buyer or seller)
        active_exchanges_query = """
            SELECT l.listing_id, l.currency, l.amount, l.accept_currency, l.location, 
                   l.status, l.created_at, l.available_until, l.will_round_to_nearest_dollar,
                   lmt.buyer_id, l.user_id as seller_id,
                   lmt.accepted_at, lmt.rejected_at,
                   MAX(lmt.updated_at) as last_activity,
                   u_buyer.FirstName as buyer_first_name, u_buyer.LastName as buyer_last_name,
                   u_seller.FirstName as seller_first_name, u_seller.LastName as seller_last_name
            FROM listings l
            JOIN listing_meeting_time lmt ON l.listing_id = lmt.listing_id
            LEFT JOIN users u_buyer ON lmt.buyer_id = u_buyer.UserId
            LEFT JOIN users u_seller ON l.user_id = u_seller.UserId
            WHERE (lmt.buyer_id = %s OR l.user_id = %s)
            AND l.status = 'active'
            AND l.available_until > NOW()
            AND lmt.rejected_at IS NULL
            GROUP BY l.listing_id
            ORDER BY last_activity DESC 
            LIMIT 10
        """
        cursor.execute(active_exchanges_query, (user_id, user_id))
        active_exchanges = cursor.fetchall()
        
        # Placeholder for pending offers (exchange_offers table is not being used)
        pending_offers = []
        
        connection.close()
        
        # Format the response data
        dashboard_data = {
            'user': {
                'userId': user_data['UserId'],
                'firstName': user_data['FirstName'],
                'lastName': user_data['LastName'],
                'email': user_data['Email'],
                'phone': user_data['Phone'],
                'userType': user_data['UserType'],
                'dateCreated': user_data['DateCreated'].isoformat() if user_data['DateCreated'] else None,
                'isActive': bool(user_data['IsActive'])
            },
            'stats': {
                'activeListings': active_listings_count,
                'activeExchanges': active_exchanges_count,
                'completedTransactions': completed_transactions_count,
                'pendingOffers': len(pending_offers)
            },
            'activeListings': [
                {
                    'listingId': listing['listing_id'],
                    'currency': listing['currency'],
                    'amount': float(listing['amount']) if isinstance(listing['amount'], Decimal) else listing['amount'],
                    'acceptCurrency': listing['accept_currency'],
                    'location': listing['location'],
                    'status': listing['status'],
                    'createdAt': listing['created_at'].isoformat() if listing['created_at'] else None,
                    'availableUntil': listing['available_until'].isoformat() if listing['available_until'] else None,
                    'willRoundToNearestDollar': bool(listing['will_round_to_nearest_dollar']) if listing['will_round_to_nearest_dollar'] is not None else False
                }
                for listing in user_listings
            ],
            'activeExchanges': [
                {
                    'listingId': exchange['listing_id'],
                    'currency': exchange['currency'],
                    'amount': float(exchange['amount']) if isinstance(exchange['amount'], Decimal) else exchange['amount'],
                    'acceptCurrency': exchange['accept_currency'],
                    'location': exchange['location'],
                    'status': exchange['status'],
                    'createdAt': exchange['created_at'].isoformat() if exchange['created_at'] else None,
                    'availableUntil': exchange['available_until'].isoformat() if exchange['available_until'] else None,
                    'willRoundToNearestDollar': bool(exchange['will_round_to_nearest_dollar']) if exchange['will_round_to_nearest_dollar'] is not None else False,
                    'userRole': 'buyer' if exchange['buyer_id'] == user_id else 'seller',
                    'otherUser': {
                        'name': f"{exchange['seller_first_name']} {exchange['seller_last_name']}" if exchange['buyer_id'] == user_id else f"{exchange['buyer_first_name']} {exchange['buyer_last_name']}"
                    },
                    'acceptedAt': exchange['accepted_at'].isoformat() if exchange['accepted_at'] else None,
                    'rejectedAt': exchange['rejected_at'].isoformat() if exchange['rejected_at'] else None,
                    'negotiationStatus': 'accepted' if exchange['accepted_at'] else 'proposed',
                    'actionRequired': exchange['accepted_at'] is None and exchange['buyer_id'] != user_id  # Seller needs to accept
                }
                for exchange in active_exchanges
            ],
            'pendingOffers': [
                {
                    'offerId': offer['offer_id'],
                    'listingId': offer['listing_id'],
                    'offeredAmount': float(offer['offered_amount']) if isinstance(offer['offered_amount'], Decimal) else offer['offered_amount'],
                    'offeredCurrency': offer['offered_currency'],
                    'message': offer['message'],
                    'createdAt': offer['created_at'].isoformat() if offer['created_at'] else None,
                    'originalListing': {
                        'currency': offer['currency'],
                        'amount': float(offer['amount']) if isinstance(offer['amount'], Decimal) else offer['amount']
                    },
                    'offerUser': {
                        'firstName': offer['FirstName'],
                        'lastName': offer['LastName']
                    }
                }
                for offer in pending_offers
            ]
        }
        
        print(f"[GetUserDashboard] Successfully retrieved dashboard data for user {user_id}")
        
        return json.dumps({
            'success': True,
            'data': dashboard_data
        })
        
    except Exception as e:
        print(f"[GetUserDashboard] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': 'Failed to retrieve dashboard data'
        })