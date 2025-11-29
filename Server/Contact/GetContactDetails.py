from _Lib import Database
import json
from datetime import datetime

def calculate_distance(lat1, lon1, lat2, lon2):
    """Calculate distance between two GPS coordinates using Haversine formula"""
    import math
    
    # Convert latitude and longitude from degrees to radians
    lat1, lon1, lat2, lon2 = map(math.radians, [lat1, lon1, lat2, lon2])
    
    # Haversine formula
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    a = math.sin(dlat/2)**2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon/2)**2
    c = 2 * math.asin(math.sqrt(a))
    
    # Radius of earth in miles
    r = 3956
    
    return round(c * r, 1)

def format_location_display(location_coords, user_lat=None, user_lng=None):
    """Convert lat/lng coordinates to distance from user's location"""
    if not location_coords or ',' not in location_coords:
        return "Location not specified"
    
    try:
        lat, lng = location_coords.split(', ')
        listing_lat = float(lat)
        listing_lng = float(lng)
        
        # If user's location is provided, calculate distance
        if user_lat is not None and user_lng is not None:
            distance = calculate_distance(user_lat, user_lng, listing_lat, listing_lng)
            return f"{distance} miles away"
        else:
            # Fallback to general location description
            return "Distance unknown (location access needed)"
            
    except (ValueError, IndexError):
        return "Location not specified"

def get_contact_details(listing_id, session_id=None, user_lat=None, user_lng=None):
    """Get detailed information about a listing and trader for contact page"""
    try:
        print(f"[GetContactDetails] Getting details for listing {listing_id}")
        
        # Connect to database
        try:
            cursor, connection = Database.ConnectToDatabase()
            print(f"[GetContactDetails] Database connection successful")
        except Exception as db_err:
            print(f"[GetContactDetails] Database connection failed: {str(db_err)}")
            raise db_err
        
        # Get detailed listing information with trader details
        query = """
            SELECT 
                l.listing_id,
                l.user_id,
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
                l.will_round_to_nearest_dollar,
                u.FirstName,
                u.LastName,
                u.Email,
                u.Phone,
                u.DateCreated as user_joined_date,
                u.DateCreated as last_active,
                u.IsActive as verified,
                4.5 as rating,
                0 as total_trades
            FROM listings l
            INNER JOIN users u ON l.user_id = u.UserId
            WHERE l.listing_id = %s 
            AND l.status = 'active'
        """
        
        print(f"[GetContactDetails] Executing query with listing_id: {listing_id}")
        try:
            cursor.execute(query, (listing_id,))
            result = cursor.fetchone()
            print(f"[GetContactDetails] Query result: {result}")
        except Exception as query_err:
            print(f"[GetContactDetails] Query execution failed: {str(query_err)}")
            print(f"[GetContactDetails] Query was: {query}")
            raise query_err
        
        if not result:
            # Check if listing exists but with different status
            cursor.execute("SELECT listing_id, status FROM listings WHERE listing_id = %s", (listing_id,))
            status_check = cursor.fetchone()
            print(f"[GetContactDetails] Status check result: {status_check}")
            return json.dumps({
                'success': False,
                'error': 'Listing not found or inactive'
            })
        
        # Format the response data
        listing_data = {
            'success': True,
            'listing': {
                'id': result['listing_id'],
                'user_id': result['user_id'],
                'currency': result['currency'],
                'amount': float(result['amount']) if result['amount'] else 0,
                'accept_currency': result['accept_currency'],
                # Custom rates not implemented - all listings use market rate
                'location': format_location_display(result['location'], user_lat, user_lng),
                'location_radius': result['location_radius'],
                'meeting_preference': result['meeting_preference'],
                'available_until': result['available_until'].isoformat() if result['available_until'] else None,
                'status': result['status'],
                'notes': '',  # Will be added later
                'created_at': result['created_at'].isoformat() if result['created_at'] else None,
                'posted_ago': calculate_time_ago(result['created_at']) if result['created_at'] else 'Unknown',
                'will_round_to_nearest_dollar': result['will_round_to_nearest_dollar'],
                'user': {
                    'name': f"{result['FirstName']} {result['LastName']}",
                    'first_name': result['FirstName'],
                    'last_name': result['LastName'],
                    'email': result['Email'] if session_id else None,  # Only show email if user has access
                    'phone': result['Phone'] if session_id else None,  # Only show phone if user has access
                    'joined_date': result['user_joined_date'].isoformat() if result['user_joined_date'] else None,
                    'last_active': calculate_time_ago(result['last_active']) if result['last_active'] else 'Unknown',
                    'verified': bool(result['verified']),
                    'profile_picture': None,
                    'languages': ['English'],  # Default
                    'response_time': 'Usually responds within 1 hour',
                    'rating': round(float(result['rating']), 1) if result['rating'] else 4.5,
                    'trades': int(result['total_trades']) if result['total_trades'] else 0
                }
            },
            'contact_fee': {
                'price': 2.00,
                'currency': 'USD',
                'features': [
                    'Direct contact with seller',
                    'Exchange coordination', 
                    'Platform protection',
                    'Dispute resolution support'
                ]
            }
        }
        
        # Close database connection
        cursor.close()
        connection.close()
        
        return json.dumps(listing_data)
        
    except Exception as e:
        print(f"[GetContactDetails] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': 'Failed to get contact details'
        })

def calculate_time_ago(timestamp):
    """Calculate human-readable time ago from timestamp"""
    if not timestamp:
        return 'Unknown'
    
    try:
        now = datetime.now()
        if isinstance(timestamp, str):
            timestamp = datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
        
        diff = now - timestamp
        
        if diff.days > 0:
            return f"{diff.days} day{'s' if diff.days != 1 else ''} ago"
        elif diff.seconds > 3600:
            hours = diff.seconds // 3600
            return f"{hours} hour{'s' if hours != 1 else ''} ago"
        elif diff.seconds > 60:
            minutes = diff.seconds // 60
            return f"{minutes} minute{'s' if minutes != 1 else ''} ago"
        else:
            return "Just now"
    except:
        return 'Unknown'

def format_response_time(avg_seconds):
    """Format average response time in seconds to human readable format"""
    if not avg_seconds:
        return 'Usually responds within 24 hours'
    
    try:
        avg_seconds = int(avg_seconds)
        
        if avg_seconds < 3600:  # Less than 1 hour
            minutes = avg_seconds // 60
            return f"Usually responds within {minutes} minute{'s' if minutes != 1 else ''}"
        elif avg_seconds < 86400:  # Less than 24 hours
            hours = avg_seconds // 3600
            return f"Usually responds within {hours} hour{'s' if hours != 1 else ''}"
        else:  # More than 24 hours
            days = avg_seconds // 86400
            return f"Usually responds within {days} day{'s' if days != 1 else ''}"
    except:
        return 'Usually responds within 24 hours'