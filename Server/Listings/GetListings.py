from _Lib import Database
import json
from decimal import Decimal

def get_listings(Currency, AcceptCurrency, Location, MaxDistance, Limit, Offset):
    """Get listings with optional filtering"""
    try:
        # Parameters are passed directly from the blueprint
        currency = Currency
        accept_currency = AcceptCurrency
        location = Location
        max_distance = MaxDistance
        limit = Limit or '20'
        offset = Offset or '0'
        
        print(f"[GetListings] Fetching listings with filters: currency={currency}, accept_currency={accept_currency}")
        
        # Connect to database
        cursor, connection = Database.ConnectToDatabase()
        
        # Build dynamic query based on filters (excluding sold/completed listings)
        base_query = """
            SELECT 
                l.listing_id,
                l.currency,
                l.amount,
                l.accept_currency,
                l.location,
                l.location_radius,
                l.meeting_preference,
                l.available_until,
                l.status,
                l.created_at,
                l.will_round_to_nearest_dollar,
                CONCAT(u.FirstName, ' ', u.LastName) as user_name,
                u.Rating as user_rating,
                u.TotalExchanges as user_total_exchanges
            FROM listings l
            JOIN users u ON l.user_id = u.user_id
            WHERE l.status = 'active' AND l.available_until > NOW()
        """
        
        params = []
        
        if currency:
            base_query += " AND l.currency = %s"
            params.append(currency)
        
        if accept_currency:
            base_query += " AND l.accept_currency = %s"
            params.append(accept_currency)
        
        if location:
            # In a real app, you'd do geographical distance calculations
            base_query += " AND l.location LIKE %s"
            params.append(f"%{location}%")
        
        # Add ordering and pagination
        base_query += " ORDER BY l.created_at DESC LIMIT %s OFFSET %s"
        params.extend([int(limit), int(offset)])
        
        cursor.execute(base_query, params)
        listings = cursor.fetchall()
        connection.close()
        
        # Format the results
        formatted_listings = []
        for listing in listings:
            formatted_listings.append({
                'id': listing['listing_id'],
                'currency': listing['currency'],
                'amount': float(listing['amount']) if isinstance(listing['amount'], Decimal) else listing['amount'],
                'acceptCurrency': listing['accept_currency'],
                'location': listing['location'],
                'locationRadius': listing['location_radius'],
                'meetingPreference': listing['meeting_preference'],
                'availableUntil': listing['available_until'].isoformat() if listing['available_until'] else None,
                'status': listing['status'],
                'createdAt': listing['created_at'].isoformat() if listing['created_at'] else None,
                'willRoundToNearestDollar': listing['will_round_to_nearest_dollar'],
                'user': {
                    'name': listing['user_name'],
                    'rating': float(listing['user_rating']) if isinstance(listing['user_rating'], Decimal) else (listing['user_rating'] or 0),
                    'totalExchanges': listing['user_total_exchanges'] or 0
                }
            })
        
        print(f"[GetListings] Found {len(formatted_listings)} listings")
        
        return json.dumps({
            'success': True,
            'listings': formatted_listings,
            'count': len(formatted_listings)
        })
        
    except Exception as e:
        print(f"[GetListings] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': 'Failed to fetch listings'
        })