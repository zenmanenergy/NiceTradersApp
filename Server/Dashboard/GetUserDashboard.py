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
        
        # Get user's active listings count (excluding sold/completed listings)
        active_listings_query = """
            SELECT COUNT(*) as count 
            FROM listings l
            WHERE l.user_id = %s 
            AND l.status = 'active'
            AND l.available_until > NOW()
            AND NOT EXISTS (
                SELECT 1 FROM exchange_transactions et 
                WHERE et.listing_id = l.listing_id 
                AND et.status = 'completed'
            )
        """
        cursor.execute(active_listings_query, (user_id,))
        active_listings_count = cursor.fetchone()['count']
        
        # Get user's completed transactions count
        completed_transactions_query = """
            SELECT COUNT(*) as count 
            FROM exchange_transactions 
            WHERE (seller_id = %s OR buyer_id = %s) AND status = 'completed'
        """
        cursor.execute(completed_transactions_query, (user_id, user_id))
        completed_transactions_count = cursor.fetchone()['count']
        
        # Get recent active listings (last 10 listings, excluding sold/completed)
        recent_listings_query = """
            SELECT listing_id, currency, amount, accept_currency, location, 
                   status, created_at, available_until
            FROM listings l
            WHERE l.user_id = %s 
            AND l.status = 'active'
            AND l.available_until > NOW()
            AND NOT EXISTS (
                SELECT 1 FROM exchange_transactions et 
                WHERE et.listing_id = l.listing_id 
                AND et.status = 'completed'
            )
            ORDER BY l.created_at DESC 
            LIMIT 10
        """
        cursor.execute(recent_listings_query, (user_id,))
        recent_listings = cursor.fetchall()
        
        # Get pending offers on user's listings
        pending_offers_query = """
            SELECT o.offer_id, o.offered_amount, o.offered_currency, o.message,
                   o.created_at, l.listing_id, l.currency, l.amount,
                   u.FirstName, u.LastName
            FROM exchange_offers o
            JOIN listings l ON o.listing_id = l.listing_id
            JOIN users u ON o.user_id = u.UserId
            WHERE l.user_id = %s AND o.status = 'pending'
            ORDER BY o.created_at DESC
            LIMIT 5
        """
        cursor.execute(pending_offers_query, (user_id,))
        pending_offers = cursor.fetchall()
        
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
                'completedTransactions': completed_transactions_count,
                'pendingOffers': len(pending_offers)
            },
            'recentListings': [
                {
                    'listingId': listing['listing_id'],
                    'currency': listing['currency'],
                    'amount': float(listing['amount']) if isinstance(listing['amount'], Decimal) else listing['amount'],
                    'acceptCurrency': listing['accept_currency'],
                    'location': listing['location'],
                    'status': listing['status'],
                    'createdAt': listing['created_at'].isoformat() if listing['created_at'] else None,
                    'availableUntil': listing['available_until'].isoformat() if listing['available_until'] else None
                }
                for listing in recent_listings
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