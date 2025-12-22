from _Lib import Database
import json
from datetime import datetime, timezone
from decimal import Decimal

def calculate_negotiation_status(exchange, user_id):
    """Calculate the human-readable negotiation status based on workflow state"""
    # Need to check payment status
    buyer_paid_at = exchange.get('buyer_paid_at')
    seller_paid_at = exchange.get('seller_paid_at')
    
    # Time proposal not yet accepted
    if exchange['accepted_at'] is None:
        # Determine who proposed
        proposer_id = exchange.get('proposed_by')
        is_current_user_proposer = (proposer_id == user_id)
        
        if is_current_user_proposer:
            return "⏳ Waiting for Acceptance"
        else:
            return "👤 Buyer Proposed a Time"
    else:
        # Time is accepted, check payment status
        is_buyer = (exchange.get('buyer_id') == user_id)
        
        if buyer_paid_at is None and seller_paid_at is None:
            # Neither has paid yet
            return "🎯 Action: Payment"
        elif buyer_paid_at is not None and seller_paid_at is None:
            # Buyer paid, seller waiting
            if is_buyer:
                return "⏳ Waiting for Seller Payment"
            else:
                return "🎯 Action: Payment"
        elif buyer_paid_at is None and seller_paid_at is not None:
            # Seller paid, buyer waiting
            if is_buyer:
                return "🎯 Action: Payment"
            else:
                return "⏳ Waiting for Buyer Payment"
        else:
            # Both paid, check location proposal status
            # Get location proposal info from the exchange
            location_accepted = exchange.get('location_accepted_at')
            has_location_proposal = exchange.get('has_location_proposal', False)
            location_proposed_by = exchange.get('location_proposed_by')
            
            if location_accepted is not None:
                # Location is accepted - ready to meet
                return "✅ Meeting confirmed"
            elif has_location_proposal:
                # Someone has proposed a location
                is_current_user_proposer = (location_proposed_by == user_id)
                if is_current_user_proposer:
                    return "⏳ Waiting for Acceptance"
                else:
                    return "👤 Buyer Proposed a Location"
            else:
                # No location proposal yet
                return "🎯 Action: Propose Location"

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
        print(f"[GetUserDashboard] User ID from session: {user_id}")
        
        # Get user profile information
        user_query = """
            SELECT user_id, FirstName, LastName, Email, Phone, UserType, DateCreated, IsActive, Rating, TotalExchanges
            FROM users 
            WHERE user_id = %s
        """
        cursor.execute(user_query, (user_id,))
        user_data = cursor.fetchone()
        print(f"[GetUserDashboard] User data: {user_data}")
        
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
                   l.status, l.created_at, l.available_until, l.will_round_to_nearest_dollar, l.buyer_id,
                   CASE WHEN lp.buyer_paid_at IS NOT NULL OR lp.seller_paid_at IS NOT NULL THEN 1 ELSE 0 END as has_payment
            FROM listings l
            LEFT JOIN listing_payments lp ON l.listing_id = lp.listing_id
            WHERE l.user_id = %s 
            AND l.status = 'active'
            AND l.available_until > NOW()
            ORDER BY l.created_at DESC 
            LIMIT 10
        """
        print(f"[GetUserDashboard] Querying user listings for user_id: {user_id}")
        cursor.execute(user_listings_query, (user_id,))
        user_listings = cursor.fetchall()
        print(f"[GetUserDashboard] Found {len(user_listings)} user listings")
        for listing in user_listings:
            print(f"[GetUserDashboard]   - Listing: {listing['listing_id']}, currency: {listing['currency']}, amount: {listing['amount']}, status: {listing['status']}")
        
        # Get user's active exchanges (listings user is negotiating on as buyer or seller)
        active_exchanges_query = """
            SELECT l.listing_id, l.currency, l.amount, l.accept_currency, l.location, 
                   l.latitude, l.longitude, l.location_radius,
                   l.status, l.created_at, l.available_until, l.will_round_to_nearest_dollar,
                   lmt.buyer_id, l.user_id as seller_id,
                   lmt.proposed_by, lmt.meeting_time, lmt.accepted_at, lmt.rejected_at,
                   lp.buyer_paid_at, lp.seller_paid_at,
                   CASE WHEN lml.location_negotiation_id IS NOT NULL THEN 1 ELSE 0 END as has_location_proposal,
                   lml.proposed_by as location_proposed_by,
                   lml.accepted_at as location_accepted_at,
                   MAX(lmt.updated_at) as last_activity,
                   u_buyer.FirstName as buyer_first_name, u_buyer.LastName as buyer_last_name,
                   u_seller.FirstName as seller_first_name, u_seller.LastName as seller_last_name
            FROM listings l
            JOIN listing_meeting_time lmt ON l.listing_id = lmt.listing_id
            LEFT JOIN listing_payments lp ON l.listing_id = lp.listing_id
            LEFT JOIN listing_meeting_location lml ON l.listing_id = lml.listing_id
            LEFT JOIN users u_buyer ON lmt.buyer_id = u_buyer.user_id
            LEFT JOIN users u_seller ON l.user_id = u_seller.user_id
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
        print(f"[GetUserDashboard] Found {len(active_exchanges)} active exchanges")
        
        # Placeholder for pending offers (exchange_offers table is not being used)
        pending_offers = []
        
        connection.close()
        
        # Format the response data
        dashboard_data = {
            'user': {
                'user_id': user_data['user_id'],
                'firstName': user_data['FirstName'],
                'lastName': user_data['LastName'],
                'email': user_data['Email'],
                'phone': user_data['Phone'],
                'userType': user_data['UserType'],
                'dateCreated': user_data['DateCreated'].isoformat() if user_data['DateCreated'] else None,
                'isActive': bool(user_data['IsActive']),
                'rating': float(user_data['Rating']) if user_data['Rating'] is not None else 0.0,
                'totalExchanges': int(user_data['TotalExchanges']) if user_data['TotalExchanges'] is not None else 0
            },
            'stats': {
                'activeListings': active_listings_count,
                'activeExchanges': active_exchanges_count,
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
                    'availableUntil': listing['available_until'].isoformat() if listing['available_until'] else None,
                    'willRoundToNearestDollar': bool(listing['will_round_to_nearest_dollar']) if listing['will_round_to_nearest_dollar'] is not None else False,
                    'hasBuyer': listing['buyer_id'] is not None,
                    'isPaid': bool(listing['has_payment'])
                }
                for listing in user_listings
            ],
            'activeExchanges': [
                {
                    'listingId': exchange['listing_id'],
                    'listing': {
                        'currency': exchange['currency'],
                        'amount': float(exchange['amount']) if isinstance(exchange['amount'], Decimal) else exchange['amount'],
                        'acceptCurrency': exchange['accept_currency'],
                        'location': exchange['location'],
                        'latitude': float(exchange['latitude']) if exchange['latitude'] is not None else 0.0,
                        'longitude': float(exchange['longitude']) if exchange['longitude'] is not None else 0.0,
                        'radius': int(exchange['location_radius']) if exchange['location_radius'] is not None else 0,
                        'willRoundToNearestDollar': bool(exchange['will_round_to_nearest_dollar']) if exchange['will_round_to_nearest_dollar'] is not None else False
                    },
                    'currency': exchange['currency'],
                    'amount': float(exchange['amount']) if isinstance(exchange['amount'], Decimal) else exchange['amount'],
                    'acceptCurrency': exchange['accept_currency'],
                    'location': exchange['location'],
                    'userRole': 'buyer' if exchange['buyer_id'] == user_id else 'seller',
                    'otherUser': {
                        'name': f"{exchange['seller_first_name']} {exchange['seller_last_name']}" if exchange['buyer_id'] == user_id else f"{exchange['buyer_first_name']} {exchange['buyer_last_name']}"
                    },
                    'negotiationStatus': 'accepted' if exchange['accepted_at'] else 'proposed',
                    'displayStatus': calculate_negotiation_status(exchange, user_id),
                    'status': exchange['status'],
                    'meetingTime': exchange.get('meeting_time').replace(tzinfo=timezone.utc).isoformat() if exchange.get('meeting_time') else None,
                    'createdAt': exchange['created_at'].isoformat() if exchange['created_at'] else None,
                    'availableUntil': exchange['available_until'].isoformat() if exchange['available_until'] else None,
                    'willRoundToNearestDollar': bool(exchange['will_round_to_nearest_dollar']) if exchange['will_round_to_nearest_dollar'] is not None else False,
                    'acceptedAt': exchange['accepted_at'].isoformat() if exchange['accepted_at'] else None,
                    'rejectedAt': exchange['rejected_at'].isoformat() if exchange['rejected_at'] else None,
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