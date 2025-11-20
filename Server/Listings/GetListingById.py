from _Lib import Database
import json

def get_listing_by_id(ListingId):
    """Get a specific listing by ID"""
    try:
        listing_id = ListingId
        
        if not listing_id:
            return json.dumps({
                'success': False,
                'error': 'Listing ID is required'
            })
        
        print(f"[GetListingById] Fetching listing: {listing_id}")
        
        # Connect to database
        cursor, connection = Database.ConnectToDatabase()
        
        query = """
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
                l.updated_at,
                u.user_id,
                u.name as user_name,
                u.email as user_email,
                u.rating as user_rating,
                u.total_exchanges as user_total_exchanges
            FROM listings l
            JOIN users u ON l.user_id = u.user_id
            WHERE l.listing_id = %s
        """
        
        cursor.execute(query, (listing_id,))
        result = cursor.fetchone()
        connection.close()
        
        if not result:
            return json.dumps({
                'success': False,
                'error': 'Listing not found'
            })
        
        listing = result
        
        formatted_listing = {
            'id': listing['listing_id'],
            'currency': listing['currency'],
            'amount': float(listing['amount']),
            'acceptCurrency': listing['accept_currency'],
            'location': listing['location'],
            'locationRadius': listing['location_radius'],
            'meetingPreference': listing['meeting_preference'],
            'availableUntil': listing['available_until'].isoformat() if listing['available_until'] else None,
            'status': listing['status'],
            'createdAt': listing['created_at'].isoformat() if listing['created_at'] else None,
            'updatedAt': listing['updated_at'].isoformat() if listing['updated_at'] else None,
            'user': {
                'id': listing['user_id'],
                'name': listing['user_name'],
                'email': listing['user_email'],
                'rating': float(listing['user_rating']) if listing['user_rating'] else 0,
                'totalExchanges': listing['user_total_exchanges'] or 0
            }
        }
        
        print(f"[GetListingById] Found listing for user: {listing['user_name']}")
        
        return json.dumps({
            'success': True,
            'listing': formatted_listing
        })
        
    except Exception as e:
        print(f"[GetListingById] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': 'Failed to fetch listing'
        })