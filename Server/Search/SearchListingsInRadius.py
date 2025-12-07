from _Lib import Database
import json
import sys

def search_listings_in_radius(session_id, listing_id, search_query, limit=5):
    """
    Search for active listings within the radius of a specified listing.
    Filters by search text matching location/title.
    """
    try:
        print(f"\n[SearchListingsInRadius] ===== SEARCH REQUEST START =====", flush=True, file=sys.stderr)
        print(f"[SearchListingsInRadius] Input Parameters:", flush=True, file=sys.stderr)
        print(f"  session_id: {session_id}", flush=True, file=sys.stderr)
        print(f"  listing_id: {listing_id}", flush=True, file=sys.stderr)
        print(f"  search_query: {search_query}", flush=True, file=sys.stderr)
        print(f"  limit: {limit}", flush=True, file=sys.stderr)
        
        # Connect to database
        cursor, connection = Database.ConnectToDatabase()
        
        # Get the reference listing (the one we're viewing)
        cursor.execute("""
            SELECT latitude, longitude, location_radius 
            FROM listings 
            WHERE listing_id = %s
        """, (listing_id,))
        
        ref_listing = cursor.fetchone()
        if not ref_listing:
            print(f"[SearchListingsInRadius] ERROR: Reference listing not found: {listing_id}", flush=True, file=sys.stderr)
            return json.dumps({
                'success': False,
                'error': 'Reference listing not found'
            })
        
        ref_lat = float(ref_listing['latitude'])
        ref_lng = float(ref_listing['longitude'])
        radius_miles = int(ref_listing['location_radius'])
        
        print(f"[SearchListingsInRadius] Reference listing found:", flush=True, file=sys.stderr)
        print(f"  latitude: {ref_lat}", flush=True, file=sys.stderr)
        print(f"  longitude: {ref_lng}", flush=True, file=sys.stderr)
        print(f"  radius_miles: {radius_miles}", flush=True, file=sys.stderr)
        
        # Convert miles to degrees (rough approximation)
        # 1 degree latitude ≈ 69 miles
        # 1 degree longitude varies by latitude, but at equator ≈ 69 miles
        lat_degree_to_miles = 69.0
        lng_degree_to_miles = 69.0 * (3.14159 / 2.0)  # Rough average
        
        max_lat_diff = radius_miles / lat_degree_to_miles
        max_lng_diff = radius_miles / lng_degree_to_miles
        
        # Search for listings within radius with matching text
        query = """
            SELECT 
                l.listing_id,
                l.currency,
                l.amount,
                l.location,
                l.latitude,
                l.longitude,
                u.FirstName,
                u.LastName,
                ROUND(SQRT(
                    POW(69.1 * (l.latitude - %s), 2) +
                    POW(69.1 * (%s - l.longitude) * COS(l.latitude / 57.3), 2)
                ) * 1.60934, 2) AS distance_km
            FROM listings l
            JOIN users u ON l.user_id = u.UserId
            WHERE l.listing_id != %s
            AND l.status = 'active'
            AND (l.available_until IS NULL OR l.available_until > NOW())
            AND ABS(l.latitude - %s) < %s
            AND ABS(l.longitude - %s) < %s
            AND (
                LOWER(l.location) LIKE %s
                OR LOWER(u.FirstName) LIKE %s
                OR LOWER(u.LastName) LIKE %s
            )
            ORDER BY distance_km ASC
            LIMIT %s
        """
        
        search_pattern = f"%{search_query.lower()}%"
        
        print(f"[SearchListingsInRadius] Search pattern: {search_pattern}", flush=True, file=sys.stderr)
        print(f"[SearchListingsInRadius] Query will search for:", flush=True, file=sys.stderr)
        print(f"  - LOWER(l.location) LIKE '{search_pattern}'", flush=True, file=sys.stderr)
        print(f"  - LOWER(u.FirstName) LIKE '{search_pattern}'", flush=True, file=sys.stderr)
        print(f"  - LOWER(u.LastName) LIKE '{search_pattern}'", flush=True, file=sys.stderr)
        
        cursor.execute(query, (
            ref_lat, ref_lng, listing_id,
            ref_lat, max_lat_diff,
            ref_lng, max_lng_diff,
            search_pattern, search_pattern, search_pattern,
            limit
        ))
        
        results = cursor.fetchall()
        
        print(f"[SearchListingsInRadius] Query executed, found {len(results)} results", flush=True, file=sys.stderr)
        
        listings = []
        for row in results:
            listings.append({
                'id': row['listing_id'],
                'title': f"{row['FirstName']} {row['LastName']}",
                'currency': row['currency'],
                'amount': float(row['amount']),
                'location': row['location'],
                'latitude': float(row['latitude']),
                'longitude': float(row['longitude']),
                'distance_km': float(row['distance_km']),
                'distance_miles': float(row['distance_km']) / 1.60934
            })
        
        connection.close()
        
        print(f"[SearchListingsInRadius] Formatted {len(listings)} listings", flush=True, file=sys.stderr)
        print(f"[SearchListingsInRadius] ===== SEARCH REQUEST END =====\n", flush=True, file=sys.stderr)
        
        return json.dumps({
            'success': True,
            'listings': listings,
            'count': len(listings),
            'reference_location': {
                'latitude': ref_lat,
                'longitude': ref_lng,
                'radius_miles': radius_miles
            }
        })
        
    except Exception as e:
        print(f"[SearchListingsInRadius] ERROR: {str(e)}", flush=True, file=sys.stderr)
        import traceback
        print(f"[SearchListingsInRadius] Traceback: {traceback.format_exc()}", flush=True, file=sys.stderr)
        return json.dumps({
            'success': False,
            'error': 'Failed to search listings'
        })
