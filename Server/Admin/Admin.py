from flask import Blueprint, request, jsonify
from flask_cors import cross_origin
from _Lib.Database import ConnectToDatabase
from APNService.APNService import APNService
import os
from datetime import datetime

blueprint = Blueprint('admin', __name__)

# Initialize APN Service with credentials
# Get the path to the APN key file (in Server directory)
APN_KEY_PATH = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'AuthKey_LST3TZH33S.p8')
APN_KEY_ID = 'LST3TZH33S'
APN_TEAM_ID = 'J7S264TV3T'
APN_TOPIC = 'NiceTraders.Nice-Traders'

apn_service = APNService(
    certificate_path=APN_KEY_PATH,
    key_id=APN_KEY_ID,
    team_id=APN_TEAM_ID,
    topic=APN_TOPIC
)

@blueprint.route('/Admin/SearchUsers', methods=['GET', 'POST'])
@cross_origin()
def search_users():
    """Search users by name or email"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        search_term = params.get('search', '')
        email = params.get('email', '')
        
        cursor, connection = ConnectToDatabase()
        
        if email:
            query = """
                SELECT * FROM users 
                WHERE Email LIKE %s
                ORDER BY DateCreated DESC
                LIMIT 100
            """
            cursor.execute(query, (f'%{email}%',))
        elif search_term:
            query = """
                SELECT * FROM users 
                WHERE FirstName LIKE %s 
                   OR LastName LIKE %s 
                   OR Email LIKE %s
                ORDER BY DateCreated DESC
                LIMIT 100
            """
            search = f'%{search_term}%'
            cursor.execute(query, (search, search, search))
        else:
            query = "SELECT * FROM users ORDER BY DateCreated DESC LIMIT 100"
            cursor.execute(query)
        
        users = cursor.fetchall()
        cursor.close()
        connection.close()
        
        return jsonify({'success': True, 'data': users})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@blueprint.route('/Admin/SearchListings', methods=['GET', 'POST'])
@cross_origin()
def search_listings():
    """Search listings"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        search_term = params.get('search', '')
        
        cursor, connection = ConnectToDatabase()
        
        if search_term:
            query = """
                SELECT * FROM listings 
                WHERE currency LIKE %s 
                   OR accept_currency LIKE %s 
                   OR location LIKE %s
                ORDER BY created_at DESC
                LIMIT 100
            """
            search = f'%{search_term}%'
            cursor.execute(query, (search, search, search))
        else:
            query = "SELECT * FROM listings ORDER BY created_at DESC LIMIT 100"
            cursor.execute(query)
        
        listings = cursor.fetchall()
        cursor.close()
        connection.close()
        
        return jsonify({'success': True, 'data': listings})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@blueprint.route('/Admin/SearchTransactions', methods=['GET', 'POST'])
@cross_origin()
def search_transactions():
    """Search transactions"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        search_term = params.get('search', '')
        
        cursor, connection = ConnectToDatabase()
        
        if search_term:
            query = """
                SELECT * FROM contact_access 
                WHERE payment_method LIKE %s 
                   OR transaction_id LIKE %s
                ORDER BY purchased_at DESC
                LIMIT 100
            """
            search = f'%{search_term}%'
            cursor.execute(query, (search, search))
        else:
            query = "SELECT * FROM contact_access ORDER BY purchased_at DESC LIMIT 100"
            cursor.execute(query)
        
        transactions = cursor.fetchall()
        cursor.close()
        connection.close()
        
        return jsonify({'success': True, 'data': transactions})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@blueprint.route('/Admin/GetUserById', methods=['GET', 'POST'])
@cross_origin()
def get_user_by_id():
    """Get user details by ID"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        user_id = params.get('userId')
        
        cursor, connection = ConnectToDatabase()
        
        query = "SELECT * FROM users WHERE UserId = %s"
        cursor.execute(query, (user_id,))
        user = cursor.fetchone()
        
        cursor.close()
        connection.close()
        
        if user:
            return jsonify({'success': True, 'user': user})
        else:
            return jsonify({'success': False, 'error': 'User not found'})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@blueprint.route('/Admin/UpdateUser', methods=['GET', 'POST'])
@cross_origin()
def update_user():
    """Update basic user information"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        user_id = params.get('userId')
        if not user_id:
            return jsonify({'success': False, 'error': 'userId is required'})

        allowed_fields = ['FirstName', 'LastName', 'Email', 'Phone', 'Location', 'Bio', 'IsActive']
        updates = {}
        for field in allowed_fields:
            if field in params and params[field] is not None:
                value = params[field]
                if field == 'IsActive':
                    if isinstance(value, str):
                        value = 1 if value.lower() in ['1', 'true', 'yes', 'on'] else 0
                    else:
                        value = 1 if value else 0
                updates[field] = value

        if not updates:
            return jsonify({'success': False, 'error': 'No fields to update'})

        cursor, connection = ConnectToDatabase()
        set_clause = ', '.join(f"{field} = %s" for field in updates.keys())
        values = list(updates.values())
        values.append(user_id)
        cursor.execute(f"UPDATE users SET {set_clause} WHERE UserId = %s", values)
        connection.commit()

        cursor.execute("SELECT * FROM users WHERE UserId = %s", (user_id,))
        user = cursor.fetchone()
        cursor.close()
        connection.close()

        return jsonify({'success': True, 'user': user})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@blueprint.route('/Admin/GetUserListings', methods=['GET', 'POST'])
@cross_origin()
def get_user_listings():
    """Get all listings for a user"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        user_id = params.get('userId')
        
        cursor, connection = ConnectToDatabase()
        
        query = "SELECT * FROM listings WHERE user_id = %s ORDER BY created_at DESC"
        cursor.execute(query, (user_id,))
        listings = cursor.fetchall()
        
        cursor.close()
        connection.close()
        
        return jsonify({'success': True, 'listings': listings})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@blueprint.route('/Admin/GetUserPurchases', methods=['GET', 'POST'])
@cross_origin()
def get_user_purchases():
    """Get all purchases by a user"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        user_id = params.get('userId')
        
        cursor, connection = ConnectToDatabase()
        
        query = "SELECT * FROM contact_access WHERE user_id = %s ORDER BY purchased_at DESC"
        cursor.execute(query, (user_id,))
        purchases = cursor.fetchall()
        
        cursor.close()
        connection.close()
        
        return jsonify({'success': True, 'purchases': purchases})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@blueprint.route('/Admin/GetUserMessages', methods=['GET', 'POST'])
@cross_origin()
def get_user_messages():
    """Get all messages for a user"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        user_id = params.get('userId')
        
        cursor, connection = ConnectToDatabase()
        
        query = """
            SELECT * FROM messages 
            WHERE sender_id = %s OR recipient_id = %s 
            ORDER BY sent_at DESC
        """
        cursor.execute(query, (user_id, user_id))
        messages = cursor.fetchall()
        
        cursor.close()
        connection.close()
        
        return jsonify({'success': True, 'messages': messages})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@blueprint.route('/Admin/GetUserRatings', methods=['GET', 'POST'])
@cross_origin()
def get_user_ratings():
    """Get all ratings for a user"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        user_id = params.get('userId')
        
        cursor, connection = ConnectToDatabase()
        
        # Check if table exists
        cursor.execute("SHOW TABLES LIKE 'user_ratings'")
        if not cursor.fetchone():
            cursor.close()
            connection.close()
            return jsonify({'success': True, 'ratings': []})
        
        query = "SELECT * FROM user_ratings WHERE user_id = %s ORDER BY created_at DESC"
        cursor.execute(query, (user_id,))
        ratings = cursor.fetchall()
        
        cursor.close()
        connection.close()
        
        return jsonify({'success': True, 'ratings': ratings})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@blueprint.route('/Admin/GetUserDevices', methods=['GET', 'POST'])
@cross_origin()
def get_user_devices():
    """Get all registered devices for a user"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        user_id = params.get('userId')
        
        cursor, connection = ConnectToDatabase()
        
        query = """
            SELECT device_id, UserId, device_type, device_token, device_name, 
                   app_version, os_version, is_active, registered_at, last_used_at, updated_at
            FROM user_devices 
            WHERE UserId = %s 
            ORDER BY last_used_at DESC, registered_at DESC
        """
        cursor.execute(query, (user_id,))
        devices = cursor.fetchall()
        
        cursor.close()
        connection.close()
        
        return jsonify({'success': True, 'devices': devices})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@blueprint.route('/Admin/GetListingById', methods=['GET', 'POST'])
@cross_origin()
def get_listing_by_id():
    """Get listing details by ID"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        listing_id = params.get('listingId')
        
        cursor, connection = ConnectToDatabase()
        
        query = "SELECT * FROM listings WHERE listing_id = %s"
        cursor.execute(query, (listing_id,))
        listing = cursor.fetchone()
        
        cursor.close()
        connection.close()
        
        if listing:
            return jsonify({'success': True, 'listing': listing})
        else:
            return jsonify({'success': False, 'error': 'Listing not found'})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@blueprint.route('/Admin/GetListingPurchases', methods=['GET', 'POST'])
@cross_origin()
def get_listing_purchases():
    """Get all purchases for a listing"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        listing_id = params.get('listingId')
        
        cursor, connection = ConnectToDatabase()
        
        query = "SELECT * FROM contact_access WHERE listing_id = %s ORDER BY purchased_at DESC"
        cursor.execute(query, (listing_id,))
        purchases = cursor.fetchall()
        
        cursor.close()
        connection.close()
        
        return jsonify({'success': True, 'purchases': purchases})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@blueprint.route('/Admin/GetListingMessages', methods=['GET', 'POST'])
@cross_origin()
def get_listing_messages():
    """Get all messages for a listing"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        listing_id = params.get('listingId')
        
        cursor, connection = ConnectToDatabase()
        
        query = "SELECT * FROM messages WHERE listing_id = %s ORDER BY sent_at DESC"
        cursor.execute(query, (listing_id,))
        messages = cursor.fetchall()
        
        cursor.close()
        connection.close()
        
        return jsonify({'success': True, 'messages': messages})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@blueprint.route('/Admin/GetTransactionById', methods=['GET', 'POST'])
@cross_origin()
def get_transaction_by_id():
    """Get transaction details by ID"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        transaction_id = params.get('transactionId')
        
        cursor, connection = ConnectToDatabase()
        
        query = "SELECT * FROM contact_access WHERE access_id = %s"
        cursor.execute(query, (transaction_id,))
        transaction = cursor.fetchone()
        
        cursor.close()
        connection.close()
        
        if transaction:
            return jsonify({'success': True, 'transaction': transaction})
        else:
            return jsonify({'success': False, 'error': 'Transaction not found'})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@blueprint.route('/Admin/SendApnMessage', methods=['GET', 'POST'])
@cross_origin()
def send_apn_message():
    """Send an Apple Push Notification (APN) to a user"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        user_id = params.get('user_id')
        title = params.get('title')
        body = params.get('body')
        badge = int(params.get('badge', 1))
        sound = params.get('sound', 'default')
        device_id = params.get('device_id')  # Optional: specific device to send to
        
        # Debug: Check library imports
        import sys
        aioapns_available = 'aioapns' in sys.modules
        apns2_available = 'apns2' in sys.modules
        
        # Check database connection
        try:
            from _Lib.Database import ConnectToDatabase
            cursor, connection = ConnectToDatabase()
            db_available = True
            # Test if user exists
            cursor.execute("SELECT UserId FROM users WHERE UserId = %s", (user_id,))
            user_exists = cursor.fetchone() is not None
            
            # Get device count
            cursor.execute("SELECT COUNT(*) as count FROM user_devices WHERE UserId = %s", (user_id,))
            device_count_result = cursor.fetchone()
            total_devices = device_count_result['count'] if device_count_result else 0
            
            # Get iOS device count
            cursor.execute("SELECT COUNT(*) as count FROM user_devices WHERE UserId = %s AND device_type = 'ios'", (user_id,))
            ios_count_result = cursor.fetchone()
            ios_devices = ios_count_result['count'] if ios_count_result else 0
            
            # Get device details
            cursor.execute(
                "SELECT device_id, device_type, device_name, device_token, is_active FROM user_devices WHERE UserId = %s ORDER BY last_used_at DESC",
                (user_id,)
            )
            devices_list = cursor.fetchall()
            device_details = []
            for dev in devices_list:
                device_details.append({
                    'device_id': dev.get('device_id'),
                    'device_type': dev.get('device_type'),
                    'device_name': dev.get('device_name'),
                    'has_token': bool(dev.get('device_token')),
                    'token_preview': dev.get('device_token', '')[:20] if dev.get('device_token') else None,
                    'is_active': dev.get('is_active')
                })
            
            cursor.close()
            connection.close()
        except Exception as db_err:
            db_available = False
            user_exists = False
            total_devices = 0
            ios_devices = 0
            device_details = []
            db_error_msg = str(db_err)
        
        if not user_id or not title or not body:
            return jsonify({
                'success': False,
                'error': 'user_id, title, and body are required',
                'debug': {
                    'aioapns_available': aioapns_available,
                    'apns2_available': apns2_available,
                    'db_available': db_available
                }
            }), 400
        
        # Send the notification
        result = apn_service.send_notification(
            user_id=user_id,
            title=title,
            body=body,
            badge=badge,
            sound=sound,
            device_id=device_id
        )
        
        # Build comprehensive debug response
        debug_response = {
            'success': result.get('success', False),
            'message': result.get('message', ''),
            'error': result.get('error'),
            'debug_apns2_in_modules': apns2_available,
            'debug': {
                'request': {
                    'user_id': user_id,
                    'device_id': device_id,
                    'title': title,
                    'body': body,
                    'badge': badge,
                    'sound': sound
                },
                'environment': {
                    'aioapns_available': aioapns_available,
                    'apns2_available': apns2_available,
                    'db_available': db_available,
                    'apn_service_configured': bool(apn_service.certificate_path and apn_service.key_id and apn_service.team_id),
                    'certificate_path': apn_service.certificate_path,
                    'certificate_exists': os.path.exists(apn_service.certificate_path) if apn_service.certificate_path else False,
                    'certificate_readable': os.access(apn_service.certificate_path, os.R_OK) if apn_service.certificate_path else False,
                    'certificate_size': os.path.getsize(apn_service.certificate_path) if apn_service.certificate_path and os.path.exists(apn_service.certificate_path) else 0,
                    'key_id': apn_service.key_id,
                    'team_id': apn_service.team_id
                },
                'database': {
                    'user_exists': user_exists,
                    'total_devices': total_devices,
                    'ios_devices': ios_devices,
                    'device_details': device_details,
                    'error': db_error_msg if db_available == False else None
                },
                'apn_service_response': {
                    'tokens_found': result.get('tokens_found'),
                    'devices_found': result.get('devices_found'),
                    'tokens_sent': result.get('tokens_sent'),
                    'failed_tokens': result.get('failed'),
                    'device_id_in_response': result.get('device_id'),
                    'query_type': result.get('query_type'),
                    'requested_device_id': result.get('requested_device_id'),
                    'full_debug': result.get('debug', {})
                }
            }
        }
        
        if result['success']:
            return jsonify(debug_response), 200
        else:
            return jsonify(debug_response), 400
    
    except Exception as e:
        import traceback
        return jsonify({
            'success': False,
            'error': str(e),
            'error_type': type(e).__name__,
            'debug': {
                'exception_trace': traceback.format_exc()
            }
        }), 500


@blueprint.route('/Admin/GetLogs', methods=['GET', 'POST'])
@cross_origin()
def get_logs():
    """Get server logs for debugging"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        log_type = params.get('type', 'flask')  # 'flask' or 'error'
        lines = int(params.get('lines', 100))  # Default to last 100 lines
        search = params.get('search', '')  # Optional search filter
        
        # Security: Limit to reasonable number of lines
        lines = min(lines, 1000)
        
        # Determine log file path
        log_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'logs')
        if log_type == 'error':
            log_file = os.path.join(log_dir, 'error.log')
        else:
            log_file = os.path.join(log_dir, 'flask_app.log')
        
        # Check if log file exists
        if not os.path.exists(log_file):
            return jsonify({
                'success': False,
                'error': f'Log file not found: {log_file}'
            })
        
        # Read the log file
        try:
            with open(log_file, 'r', encoding='utf-8', errors='ignore') as f:
                all_lines = f.readlines()
            
            # Get last N lines
            recent_lines = all_lines[-lines:] if len(all_lines) > lines else all_lines
            
            # Apply search filter if provided
            if search:
                recent_lines = [line for line in recent_lines if search.lower() in line.lower()]
            
            # Get file metadata
            file_stats = os.stat(log_file)
            file_size = file_stats.st_size
            last_modified = datetime.fromtimestamp(file_stats.st_mtime).isoformat()
            
            return jsonify({
                'success': True,
                'log_type': log_type,
                'log_file': log_file,
                'total_lines': len(all_lines),
                'returned_lines': len(recent_lines),
                'file_size_bytes': file_size,
                'last_modified': last_modified,
                'logs': ''.join(recent_lines)
            })
        
        except Exception as read_error:
            return jsonify({
                'success': False,
                'error': f'Error reading log file: {str(read_error)}'
            })
    
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@blueprint.route('/Admin/ClearLogs', methods=['POST'])
@cross_origin()
def clear_logs():
    """Clear server logs (use with caution)"""
    try:
        params = request.get_json()
        log_type = params.get('type', 'flask')  # 'flask' or 'error'
        
        # Determine log file path
        log_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'logs')
        if log_type == 'error':
            log_file = os.path.join(log_dir, 'error.log')
        else:
            log_file = os.path.join(log_dir, 'flask_app.log')
        
        # Check if log file exists
        if not os.path.exists(log_file):
            return jsonify({
                'success': False,
                'error': f'Log file not found: {log_file}'
            })
        
        # Clear the log file
        try:
            with open(log_file, 'w') as f:
                f.write('')
            
            return jsonify({
                'success': True,
                'message': f'{log_type} log cleared successfully',
                'log_file': log_file
            })
        
        except Exception as clear_error:
            return jsonify({
                'success': False,
                'error': f'Error clearing log file: {str(clear_error)}'
            })
    
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

