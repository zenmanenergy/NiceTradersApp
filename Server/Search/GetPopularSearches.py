from _Lib import Database
import json

def get_popular_searches():
    """Get popular search terms and trending currencies"""
    try:
        print("[GetPopularSearches] Fetching popular searches")
        
        # Connect to database
        cursor, connection = Database.ConnectToDatabase()
        
        # Get most popular currency pairs
        cursor.execute("""
            SELECT 
                currency,
                accept_currency,
                COUNT(*) as listing_count
            FROM listings 
            WHERE status = 'active' 
            GROUP BY currency, accept_currency
            ORDER BY listing_count DESC
            LIMIT 10
        """)
        popular_pairs = cursor.fetchall()
        
        # Get most active locations
        cursor.execute("""
            SELECT 
                location,
                COUNT(*) as listing_count
            FROM listings 
            WHERE status = 'active' AND location IS NOT NULL AND location != ''
            GROUP BY location
            ORDER BY listing_count DESC
            LIMIT 10
        """)
        popular_locations = cursor.fetchall()
        
        # Get recent search trends (currencies with most recent listings)
        cursor.execute("""
            SELECT 
                currency,
                COUNT(*) as recent_count
            FROM listings 
            WHERE status = 'active' AND created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
            GROUP BY currency
            ORDER BY recent_count DESC
            LIMIT 5
        """)
        trending_currencies = cursor.fetchall()
        
        connection.close()
        
        # Format the response
        formatted_pairs = []
        for pair in popular_pairs:
            formatted_pairs.append({
                'currency': pair['currency'],
                'acceptCurrency': pair['accept_currency'],
                'listingCount': pair['listing_count']
            })
            
        formatted_locations = []
        for location in popular_locations:
            formatted_locations.append({
                'location': location['location'],
                'listingCount': location['listing_count']
            })
            
        formatted_trending = []
        for currency in trending_currencies:
            formatted_trending.append({
                'currency': currency['currency'],
                'recentCount': currency['recent_count']
            })
        
        print(f"[GetPopularSearches] Found {len(formatted_pairs)} popular pairs, {len(formatted_locations)} locations, {len(formatted_trending)} trending")
        
        return json.dumps({
            'success': True,
            'popularPairs': formatted_pairs,
            'popularLocations': formatted_locations,
            'trendingCurrencies': formatted_trending
        })
        
    except Exception as e:
        print(f"[GetPopularSearches] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': 'Failed to get popular searches'
        })