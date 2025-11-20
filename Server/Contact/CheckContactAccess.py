from _Lib import Database
import json

def check_contact_access(listing_id, session_id):
    """Check if user already has paid contact access to a specific listing"""
    try:
        print(f"[CheckContactAccess] Checking access for listing {listing_id}, session {session_id}")
        
        # Connect to database
        cursor, connection = Database.ConnectToDatabase()
        
        # First, get user_id from session_id
        cursor.execute("SELECT UserId FROM usersessions WHERE SessionId = %s", (session_id,))
        session_result = cursor.fetchone()
        print(f"[CheckContactAccess] Session lookup result: {session_result}")
        
        if not session_result:
            print(f"[CheckContactAccess] Session not found for ID: {session_id}")
            return json.dumps({
                'success': False,
                'error': 'Invalid or expired session'
            })
        
        user_id = session_result['UserId']
        print(f"[CheckContactAccess] Found user_id: {user_id}")
        
        # Check if user has active contact access for this listing
        access_query = """
            SELECT 
                access_id,
                purchased_at,
                expires_at,
                status
            FROM contact_access 
            WHERE user_id = %s 
            AND listing_id = %s 
            AND status = 'active'
            AND (expires_at IS NULL OR expires_at > NOW())
            ORDER BY purchased_at DESC
            LIMIT 1
        """
        
        print(f"[CheckContactAccess] About to execute access query with user_id={user_id}, listing_id={listing_id}")
        try:
            cursor.execute(access_query, (user_id, listing_id))
            access_result = cursor.fetchone()
            print(f"[CheckContactAccess] Access query result: {access_result}")
        except Exception as db_error:
            print(f"[CheckContactAccess] Database query error: {str(db_error)}")
            print(f"[CheckContactAccess] Error type: {type(db_error)}")
            raise db_error
        
        has_access = bool(access_result)
        
        response_data = {
            'success': True,
            'has_access': has_access,
            'user_id': user_id
        }
        
        # If user has access, include access details
        if has_access:
            response_data['access_details'] = {
                'access_id': access_result['access_id'],
                'purchased_at': access_result['purchased_at'].isoformat() if access_result['purchased_at'] else None,
                'expires_at': access_result['expires_at'].isoformat() if access_result['expires_at'] else None,
                'status': access_result['status']
            }
        
        # Close database connection
        cursor.close()
        connection.close()
        
        return json.dumps(response_data)
        
    except Exception as e:
        print(f"[CheckContactAccess] Error: {str(e)}")
        return json.dumps({
            'success': False,
            'error': 'Failed to check contact access'
        })