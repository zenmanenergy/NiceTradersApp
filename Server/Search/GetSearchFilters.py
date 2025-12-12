from _Lib import Database
import json

def get_search_filters():
    """Get available filter options for search"""
    try:
        print("[GetSearchFilters] Fetching filter options")
        
        # Connect to database
        cursor, connection = Database.ConnectToDatabase()
        
        # Get distinct currencies for "I have" dropdown (what sellers will accept)
        # When a user has currency X, they want listings where accept_currency = X
        cursor.execute("""
            SELECT DISTINCT accept_currency 
            FROM listings l
            WHERE l.status = 'active' 
            AND l.available_until > NOW()
            ORDER BY accept_currency
        """)
        currencies = [row['accept_currency'] for row in cursor.fetchall()]
        
        # Get distinct currencies for "I want" dropdown (what sellers have)
        # When a user wants currency Y, they want listings where currency = Y
        cursor.execute("""
            SELECT DISTINCT currency 
            FROM listings l
            WHERE l.status = 'active' 
            AND l.available_until > NOW()
            ORDER BY currency
        """)
        accept_currencies = [row['currency'] for row in cursor.fetchall()]
        
        # Get distinct locations
        cursor.execute("""
            SELECT DISTINCT location 
            FROM listings l
            WHERE l.status = 'active' AND l.location IS NOT NULL AND l.location != ''
            AND l.available_until > NOW()
            ORDER BY location
        """)
        locations = [row['location'] for row in cursor.fetchall()]
        
        # Get amount ranges
        cursor.execute("""
            SELECT 
                MIN(amount) as min_amount,
                MAX(amount) as max_amount,
                AVG(amount) as avg_amount
            FROM listings l
            WHERE l.status = 'active'
            AND l.available_until > NOW()
        """)
        amount_stats = cursor.fetchone()
        
        connection.close()
        
        print(f"[GetSearchFilters] Found {len(currencies)} currencies, {len(accept_currencies)} accept currencies, {len(locations)} locations")
        
        return json.dumps({
            'success': True,
            'currencies': currencies,
            'acceptCurrencies': accept_currencies,
            'locations': locations,
            'amountRange': {
                'min': float(amount_stats['min_amount']) if amount_stats['min_amount'] else 0,
                'max': float(amount_stats['max_amount']) if amount_stats['max_amount'] else 1000000,
                'average': float(amount_stats['avg_amount']) if amount_stats['avg_amount'] else 0
            }
        })
        
    except Exception as e:
        print(f"[GetSearchFilters] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': 'Failed to get search filters'
        })