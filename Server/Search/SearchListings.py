from _Lib import Database
import json
from datetime import datetime
from decimal import Decimal

def search_listings(Currency=None, AcceptCurrency=None, Location=None, MaxDistance=None, UserLatitude=None, UserLongitude=None, MinAmount=None, MaxAmount=None, SessionId=None, Limit=None, Offset=None):
    """Search for currency exchange listings with filters"""
    try:
        # Connect to database
        cursor, connection = Database.ConnectToDatabase()
        
        # Get current user ID from session to exclude their own listings
        current_user_id = None
        if SessionId:
            cursor.execute("SELECT user_id FROM usersessions WHERE SessionId = %s", (SessionId,))
            session_result = cursor.fetchone()
            if session_result:
                current_user_id = session_result['user_id']
        
        # Build the base query (excluding sold/completed listings and proposals by current user)
        base_query = """
            SELECT 
                l.listing_id,
                l.user_id,
                l.currency,
                l.amount,
                l.accept_currency,
                l.location,
                l.latitude,
                l.longitude,
                l.location_radius,
                l.meeting_preference,
                l.available_until,
                l.status,
                l.created_at,
                l.updated_at,
                l.will_round_to_nearest_dollar,
                u.FirstName,
                u.LastName,
                u.Email,
                u.Rating,
                u.TotalExchanges
            FROM listings l
            JOIN users u ON l.user_id = u.user_id
            WHERE l.status = 'active' AND l.available_until > NOW()
        """
        
        # Build filter conditions
        conditions = []
        params = []
        
        # Exclude current user's own listings
        if current_user_id:
            conditions.append("l.user_id != %s")
            params.append(current_user_id)
            # Exclude listings where current user has a pending proposal
            conditions.append("""l.listing_id NOT IN (
                SELECT listing_id FROM listing_meeting_time 
                WHERE buyer_id = %s AND accepted_at IS NULL AND rejected_at IS NULL
            )""")
            params.append(current_user_id)
        
        if Currency:
            conditions.append("l.currency = %s")
            params.append(Currency)
            print(f"[SearchListings] Added currency filter: {Currency}")
            
        if AcceptCurrency:
            conditions.append("l.accept_currency = %s")
            params.append(AcceptCurrency)
            print(f"[SearchListings] Added acceptCurrency filter: {AcceptCurrency}")
            
        if Location:
            # Simple location search - in production would use geographic distance calculation
            conditions.append("l.location LIKE %s")
            params.append(f"%{Location}%")
            print(f"[SearchListings] Added location filter: {Location}")
        
        # Distance-based filtering using Haversine formula
        if MaxDistance and UserLatitude and UserLongitude:
            try:
                max_dist_km = float(MaxDistance)
                user_lat = float(UserLatitude)
                user_lng = float(UserLongitude)
                
                # Haversine formula for distance calculation (in km)
                # This filters listings within the specified distance
                distance_condition = f"""
                    (6371 * acos(
                        cos(radians({user_lat})) * cos(radians(l.latitude)) *
                        cos(radians(l.longitude) - radians({user_lng})) +
                        sin(radians({user_lat})) * sin(radians(l.latitude))
                    )) <= %s
                """
                conditions.append(distance_condition)
                params.append(max_dist_km)
                print(f"[SearchListings] Added distance filter: {max_dist_km}km from ({user_lat}, {user_lng})")
            except (ValueError, TypeError) as e:
                print(f"[SearchListings] Invalid distance parameters: {e}")
            
        if MinAmount:
            conditions.append("l.amount >= %s")
            params.append(float(MinAmount))
            
        if MaxAmount:
            conditions.append("l.amount <= %s")
            params.append(float(MaxAmount))
        
        # Add conditions to query
        if conditions:
            base_query += " AND " + " AND ".join(conditions)
            
        # Add ordering and pagination
        base_query += " ORDER BY l.created_at DESC"
        
        # Set defaults for pagination
        limit_val = int(Limit) if Limit else 20
        offset_val = int(Offset) if Offset else 0
        
        base_query += " LIMIT %s"
        params.append(limit_val)
        
        if offset_val > 0:
            base_query += " OFFSET %s"
            params.append(offset_val)
        
        print(f"\n[SearchListings] Final SQL Query:")
        print(f"[SearchListings] {base_query}")
        print(f"[SearchListings] Parameters: {params}")
        print(f"[SearchListings] Total params: {len(params)}")
        
        cursor.execute(base_query, tuple(params))
        listings = cursor.fetchall()
        
        print(f"[SearchListings] Query executed successfully, returned {len(listings)} rows")
        
        # Get total count for pagination
        count_query = """
            SELECT COUNT(*) as total
            FROM listings l
            WHERE l.status = 'active' AND l.available_until > NOW()
        """
        
        # Build count params - must match the order of conditions in base_query
        count_conditions_for_count = list(conditions)  # Copy the conditions list
        count_params = list(params[:len(count_conditions_for_count)])  # Only use params for conditions, not pagination
        
        if count_conditions_for_count:
            count_query += " AND " + " AND ".join(count_conditions_for_count)
            
        cursor.execute(count_query, tuple(count_params))
        total_count = cursor.fetchone()['total']
        
        connection.close()
        
        # Format the response data
        formatted_listings = []
        for listing in listings:
            formatted_listings.append({
                'id': listing['listing_id'],
                'listingId': listing['listing_id'],
                'currency': listing['currency'],
                'amount': float(listing['amount']) if isinstance(listing['amount'], Decimal) else listing['amount'],
                'acceptCurrency': listing['accept_currency'],
                'location': listing['location'],
                'latitude': float(listing['latitude']) if listing['latitude'] and isinstance(listing['latitude'], Decimal) else listing['latitude'],
                'longitude': float(listing['longitude']) if listing['longitude'] and isinstance(listing['longitude'], Decimal) else listing['longitude'],
                'meetingPreference': listing['meeting_preference'],
                'availableUntil': listing['available_until'].isoformat() if listing['available_until'] else None,
                'status': listing['status'],
                'createdAt': listing['created_at'].isoformat() if listing['created_at'] else None,
                'willRoundToNearestDollar': bool(listing['will_round_to_nearest_dollar']) if listing['will_round_to_nearest_dollar'] is not None else False,
                'user': {
                    'firstName': listing['FirstName'],
                    'rating': float(listing['Rating']) if listing['Rating'] and isinstance(listing['Rating'], Decimal) else (float(listing['Rating']) if listing['Rating'] else None),
                    'trades': listing['TotalExchanges'] if listing['TotalExchanges'] else None,
                    'verified': (float(listing['Rating']) if isinstance(listing['Rating'], Decimal) else listing['Rating']) >= 4.5 if listing['Rating'] else False
                }
            })
        
        print(f"[SearchListings] Found {len(formatted_listings)} listings out of {total_count} total")
        
        print(f"\n[SearchListings] Response data:")
        print(f"  - Total listings in DB: {total_count}")
        print(f"  - Returned in this page: {len(formatted_listings)}")
        print(f"  - Pagination offset: {offset_val}")
        print(f"  - Has more: {offset_val + len(formatted_listings) < total_count}")
        print(f"[SearchListings] ===== SEARCH REQUEST END =====\n")
        
        return json.dumps({
            'success': True,
            'listings': formatted_listings,
            'pagination': {
                'total': total_count,
                'limit': limit_val,
                'offset': offset_val,
                'hasMore': offset_val + len(formatted_listings) < total_count
            }
        })
        
    except Exception as e:
        print(f"\n[SearchListings] ERROR: {str(e)}")
        import traceback
        print(f"[SearchListings] Traceback: {traceback.format_exc()}")
        return json.dumps({
            'success': False,
            'error': f'Failed to search listings: {str(e)}'
        })