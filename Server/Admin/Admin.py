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
                SELECT lp.*, l.currency, l.amount, u1.FirstName as buyer_name, u2.FirstName as seller_name
                FROM listing_payments lp
                JOIN listings l ON lp.listing_id = l.listing_id
                JOIN users u1 ON lp.buyer_id = u1.user_id
                JOIN users u2 ON l.user_id = u2.user_id
                WHERE l.currency LIKE %s 
                   OR lp.transaction_id LIKE %s
                   OR u1.FirstName LIKE %s
                   OR u2.FirstName LIKE %s
                ORDER BY lp.created_at DESC
                LIMIT 100
            """
            search = f'%{search_term}%'
            cursor.execute(query, (search, search, search, search))
        else:
            query = """
                SELECT lp.*, l.currency, l.amount, u1.FirstName as buyer_name, u2.FirstName as seller_name
                FROM listing_payments lp
                JOIN listings l ON lp.listing_id = l.listing_id
                JOIN users u1 ON lp.buyer_id = u1.user_id
                JOIN users u2 ON l.user_id = u2.user_id
                ORDER BY lp.created_at DESC
                LIMIT 100
            """
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
        user_id = params.get('user_id')
        
        cursor, connection = ConnectToDatabase()
        
        query = "SELECT * FROM users WHERE user_id = %s"
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
        user_id = params.get('user_id')
        if not user_id:
            return jsonify({'success': False, 'error': 'user_id is required'})

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
        cursor.execute(f"UPDATE users SET {set_clause} WHERE user_id = %s", values)
        connection.commit()

        cursor.execute("SELECT * FROM users WHERE user_id = %s", (user_id,))
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
        user_id = params.get('user_id')
        
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
    """Get all negotiations where user is the buyer"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        user_id = params.get('user_id')
        
        cursor, connection = ConnectToDatabase()
        
        query = """
            SELECT lmt.listing_id, l.currency, l.amount, lmt.meeting_time, 
                   lp.buyer_paid_at, lp.seller_paid_at
            FROM listing_meeting_time lmt
            JOIN listings l ON lmt.listing_id = l.listing_id
            LEFT JOIN listing_payments lp ON l.listing_id = lp.listing_id
            WHERE lmt.buyer_id = %s
            ORDER BY lmt.created_at DESC
        """
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
        user_id = params.get('user_id')
        
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
        user_id = params.get('user_id')
        
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
        user_id = params.get('user_id')
        
        cursor, connection = ConnectToDatabase()
        
        query = """
            SELECT device_id, user_id, device_type, device_token, device_name, 
                   app_version, os_version, is_active, registered_at, last_used_at, updated_at
            FROM user_devices 
            WHERE user_id = %s 
            ORDER BY last_used_at DESC, registered_at DESC
        """
        cursor.execute(query, (user_id,))
        devices = cursor.fetchall()
        
        # Convert datetime objects to ISO format strings
        for device in devices:
            if device.get('registered_at'):
                device['registered_at'] = device['registered_at'].isoformat()
            if device.get('last_used_at'):
                device['last_used_at'] = device['last_used_at'].isoformat()
            if device.get('updated_at'):
                device['updated_at'] = device['updated_at'].isoformat()
        
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
    """Get all negotiations for a listing (where user is seller)"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        listing_id = params.get('listingId')
        
        cursor, connection = ConnectToDatabase()
        
        query = """
            SELECT lmt.buyer_id, u.FirstName, u.LastName, lmt.meeting_time,
                   lp.buyer_paid_at, lp.seller_paid_at
            FROM listing_meeting_time lmt
            JOIN users u ON lmt.buyer_id = u.user_id
            LEFT JOIN listing_payments lp ON lmt.listing_id = lp.listing_id
            WHERE lmt.listing_id = %s
            ORDER BY lmt.created_at DESC
        """
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
    """Get payment transaction details by ID"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        transaction_id = params.get('transactionId')
        
        cursor, connection = ConnectToDatabase()
        
        query = "SELECT * FROM listing_payments WHERE payment_id = %s"
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
            cursor.execute("SELECT user_id FROM users WHERE user_id = %s", (user_id,))
            user_exists = cursor.fetchone() is not None
            
            # Get device count
            cursor.execute("SELECT COUNT(*) as count FROM user_devices WHERE user_id = %s", (user_id,))
            device_count_result = cursor.fetchone()
            total_devices = device_count_result['count'] if device_count_result else 0
            
            # Get iOS device count
            cursor.execute("SELECT COUNT(*) as count FROM user_devices WHERE user_id = %s AND device_type = 'ios'", (user_id,))
            ios_count_result = cursor.fetchone()
            ios_devices = ios_count_result['count'] if ios_count_result else 0
            
            # Get device details
            cursor.execute(
                "SELECT device_id, device_type, device_name, device_token, is_active FROM user_devices WHERE user_id = %s ORDER BY last_used_at DESC",
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
        # Get the user's latest session ID for auto-login
        try:
            cursor, connection = ConnectToDatabase()
            cursor.execute(
                "SELECT SessionId FROM usersessions WHERE user_id = %s ORDER BY DateAdded DESC LIMIT 1",
                (user_id,)
            )
            session_result = cursor.fetchone()
            session_id = session_result['SessionId'] if session_result else None
            cursor.close()
            connection.close()
        except Exception as sess_err:
            session_id = None
            print(f"Error fetching session ID: {sess_err}")
        
        result = apn_service.send_notification(
            user_id=user_id,
            title=title,
            body=body,
            badge=badge,
            sound=sound,
            device_id=device_id,
            session_id=session_id  # Auto-include session ID for auto-login
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
                    'session_id_sent': session_id,
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


@blueprint.route('/Admin/GetPaymentReports', methods=['GET', 'POST'])
@cross_origin()
def get_payment_reports():
    """Get payment reports with filtering and statistics"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        
        # Get optional filters
        start_date = params.get('start_date')
        end_date = params.get('end_date')
        payment_method = params.get('payment_method')  # 'paypal', 'stripe', etc.
        status = params.get('status')  # 'completed', 'pending', 'failed'
        
        cursor, connection = ConnectToDatabase()
        
        # Build base query - join with paypal_orders and users to get amount and buyer name
        query = "SELECT lp.*, po.amount, po.currency, po.status as payment_status, u.FirstName, u.LastName FROM listing_payments lp LEFT JOIN paypal_orders po ON lp.buyer_transaction_id = po.transaction_id LEFT JOIN users u ON lp.buyer_id = u.user_id WHERE 1=1"
        query_params = []
        
        # Add filters
        if start_date:
            query += " AND lp.created_at >= %s"
            query_params.append(start_date)
        
        if end_date:
            query += " AND lp.created_at <= %s"
            query_params.append(end_date)
        
        if payment_method:
            query += " AND lp.payment_method = %s"
            query_params.append(payment_method)
        
        if status:
            query += " AND po.status = %s"
            query_params.append(status)
        
        # Get all matching transactions
        query += " ORDER BY lp.created_at DESC"
        cursor.execute(query, query_params)
        transactions = cursor.fetchall()
        
        # Calculate statistics
        stats_query = """
            SELECT 
                COUNT(*) as total_transactions,
                SUM(po.amount) as total_amount,
                AVG(po.amount) as average_amount
            FROM listing_payments lp
            LEFT JOIN paypal_orders po ON lp.buyer_transaction_id = po.transaction_id
            WHERE 1=1
        """
        stats_params = []
        
        if start_date:
            stats_query += " AND lp.created_at >= %s"
            stats_params.append(start_date)
        
        if end_date:
            stats_query += " AND lp.created_at <= %s"
            stats_params.append(end_date)
        
        if payment_method:
            stats_query += " AND lp.payment_method = %s"
            stats_params.append(payment_method)
        
        cursor.execute(stats_query, stats_params)
        stats = cursor.fetchone()
        
        # Get payment method breakdown
        method_query = """
            SELECT 
                lp.payment_method,
                COUNT(*) as count,
                SUM(po.amount) as total
            FROM listing_payments lp
            LEFT JOIN paypal_orders po ON lp.buyer_transaction_id = po.transaction_id
            WHERE 1=1
        """
        method_params = []
        
        if start_date:
            method_query += " AND lp.created_at >= %s"
            method_params.append(start_date)
        
        if end_date:
            method_query += " AND lp.created_at <= %s"
            method_params.append(end_date)
        
        method_query += " GROUP BY lp.payment_method ORDER BY total DESC"
        cursor.execute(method_query, method_params)
        payment_methods = cursor.fetchall()
        
        cursor.close()
        connection.close()
        
        return jsonify({
            'success': True,
            'transactions': transactions,
            'stats': stats,
            'payment_methods': payment_methods,
            'count': len(transactions) if transactions else 0
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


@blueprint.route('/Admin/UpdateListing', methods=['GET', 'POST'])
@cross_origin()
def update_listing():
    """Update a listing as admin"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        listing_id = params.get('listing_id')
        
        if not listing_id:
            return jsonify({'success': False, 'error': 'listing_id is required'})
        
        cursor, connection = ConnectToDatabase()
        
        # Build update query dynamically
        allowed_fields = ['currency', 'amount', 'accept_currency', 'location', 'latitude', 
                         'longitude', 'location_radius', 'meeting_preference', 
                         'available_until', 'status', 'will_round_to_nearest_dollar',
                         'geocoded_location']
        
        updates = {}
        for field in allowed_fields:
            if field in params and params[field] is not None:
                value = params[field]
                
                # Type conversions
                if field in ['latitude', 'longitude']:
                    try:
                        value = float(value)
                    except (ValueError, TypeError):
                        continue
                elif field == 'amount':
                    try:
                        value = float(value)
                    except (ValueError, TypeError):
                        continue
                elif field == 'location_radius':
                    try:
                        value = int(value)
                    except (ValueError, TypeError):
                        continue
                elif field == 'will_round_to_nearest_dollar':
                    value = 1 if str(value).lower() in ['1', 'true', 'yes'] else 0
                
                updates[field] = value
        
        if not updates:
            cursor.close()
            connection.close()
            return jsonify({'success': False, 'error': 'No fields to update'})
        
        # Add updated_at timestamp
        set_clause = ', '.join(f"`{field}` = %s" for field in updates.keys())
        set_clause += ', updated_at = NOW()'
        values = list(updates.values())
        
        query = f"UPDATE listings SET {set_clause} WHERE listing_id = %s"
        values.append(listing_id)
        
        cursor.execute(query, values)
        connection.commit()
        
        affected_rows = cursor.rowcount
        cursor.close()
        connection.close()
        
        if affected_rows > 0:
            return jsonify({'success': True, 'message': 'Listing updated successfully'})
        else:
            return jsonify({'success': False, 'error': 'Listing not found'})
    
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@blueprint.route('/Admin/DeleteListing', methods=['GET', 'POST'])
@cross_origin()
def delete_listing():
    """Delete or deactivate a listing as admin"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        listing_id = params.get('listing_id')
        permanent = params.get('permanent', 'false').lower() in ['true', '1', 'yes']
        
        if not listing_id:
            return jsonify({'success': False, 'error': 'listing_id is required'})
        
        cursor, connection = ConnectToDatabase()
        
        if permanent:
            # Permanently delete the listing
            query = "DELETE FROM listings WHERE listing_id = %s"
            cursor.execute(query, (listing_id,))
        else:
            # Just deactivate the listing
            query = "UPDATE listings SET status = 'inactive', updated_at = NOW() WHERE listing_id = %s"
            cursor.execute(query, (listing_id,))
        
        connection.commit()
        affected_rows = cursor.rowcount
        cursor.close()
        connection.close()
        
        if affected_rows > 0:
            action = 'deleted' if permanent else 'deactivated'
            return jsonify({'success': True, 'message': f'Listing {action} successfully'})
        else:
            return jsonify({'success': False, 'error': 'Listing not found'})
    
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@blueprint.route('/Admin/BulkUpdateListings', methods=['POST'])
@cross_origin()
def bulk_update_listings():
    """Bulk update listings status or other fields"""
    try:
        params = request.get_json()
        listing_ids = params.get('listing_ids', [])
        updates = params.get('updates', {})
        
        if not listing_ids:
            return jsonify({'success': False, 'error': 'listing_ids is required'})
        
        if not updates:
            return jsonify({'success': False, 'error': 'updates is required'})
        
        cursor, connection = ConnectToDatabase()
        
        # Build update query
        allowed_fields = ['status', 'currency', 'amount', 'accept_currency', 'location',
                         'latitude', 'longitude', 'location_radius', 'meeting_preference',
                         'available_until', 'will_round_to_nearest_dollar', 'geocoded_location']
        
        valid_updates = {}
        for field in allowed_fields:
            if field in updates:
                valid_updates[field] = updates[field]
        
        if not valid_updates:
            cursor.close()
            connection.close()
            return jsonify({'success': False, 'error': 'No valid fields to update'})
        
        # Build placeholders for listing IDs
        id_placeholders = ','.join(['%s'] * len(listing_ids))
        set_clause = ', '.join(f"`{field}` = %s" for field in valid_updates.keys())
        set_clause += ', updated_at = NOW()'
        
        query = f"UPDATE listings SET {set_clause} WHERE listing_id IN ({id_placeholders})"
        values = list(valid_updates.values()) + listing_ids
        
        cursor.execute(query, values)
        connection.commit()
        
        affected_rows = cursor.rowcount
        cursor.close()
        connection.close()
        
        return jsonify({
            'success': True,
            'message': f'{affected_rows} listings updated successfully',
            'affected_rows': affected_rows
        })
    
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@blueprint.route('/Admin/GetListingMeetingTimes', methods=['GET', 'POST'])
@cross_origin()
def get_listing_meeting_times():
    """Get all meeting times (negotiations) for a listing"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        listing_id = params.get('listing_id')
        
        if not listing_id:
            return jsonify({'success': False, 'error': 'listing_id is required'})
        
        cursor, connection = ConnectToDatabase()
        
        # Get meeting time data from listing_meeting_location table
        query = """
            SELECT 
                lml.location_negotiation_id,
                lml.listing_id,
                lml.buyer_id,
                u.FirstName as buyer_first_name,
                u.LastName as buyer_last_name,
                lml.proposed_by,
                u2.FirstName as proposed_by_first_name,
                u2.LastName as proposed_by_last_name,
                lml.meeting_location_lat,
                lml.meeting_location_lng,
                lml.meeting_location_name,
                lml.accepted_at,
                lml.rejected_at,
                lml.created_at,
                lml.updated_at
            FROM listing_meeting_location lml
            JOIN users u ON lml.buyer_id = u.user_id
            JOIN users u2 ON lml.proposed_by = u2.user_id
            WHERE lml.listing_id = %s
            ORDER BY lml.created_at DESC
        """
        cursor.execute(query, (listing_id,))
        meetings = cursor.fetchall()
        
        cursor.close()
        connection.close()
        
        return jsonify({
            'success': True,
            'listing_id': listing_id,
            'meetings': meetings,
            'count': len(meetings) if meetings else 0
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@blueprint.route('/Admin/GetListingLocations', methods=['GET', 'POST'])
@cross_origin()
def get_listing_locations():
    """Get all proposed meeting locations for a listing"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        listing_id = params.get('listing_id')
        
        if not listing_id:
            return jsonify({'success': False, 'error': 'listing_id is required'})
        
        cursor, connection = ConnectToDatabase()
        
        # Get location negotiation data
        query = """
            SELECT 
                lml.location_negotiation_id,
                lml.listing_id,
                lml.buyer_id,
                u.FirstName as buyer_first_name,
                u.LastName as buyer_last_name,
                u.Email as buyer_email,
                lml.proposed_by,
                u2.FirstName as proposed_by_first_name,
                u2.LastName as proposed_by_last_name,
                lml.meeting_location_lat,
                lml.meeting_location_lng,
                lml.meeting_location_name,
                CASE 
                    WHEN lml.accepted_at IS NOT NULL THEN 'accepted'
                    WHEN lml.rejected_at IS NOT NULL THEN 'rejected'
                    ELSE 'pending'
                END as status,
                lml.accepted_at,
                lml.rejected_at,
                lml.created_at,
                lml.updated_at
            FROM listing_meeting_location lml
            JOIN users u ON lml.buyer_id = u.user_id
            JOIN users u2 ON lml.proposed_by = u2.user_id
            WHERE lml.listing_id = %s
            ORDER BY lml.created_at DESC
        """
        cursor.execute(query, (listing_id,))
        locations = cursor.fetchall()
        
        cursor.close()
        connection.close()
        
        return jsonify({
            'success': True,
            'listing_id': listing_id,
            'locations': locations,
            'count': len(locations) if locations else 0
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@blueprint.route('/Admin/GetListingPayments', methods=['GET', 'POST'])
@cross_origin()
def get_listing_payments():
    """Get payment details for a listing"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        listing_id = params.get('listing_id')
        
        if not listing_id:
            return jsonify({'success': False, 'error': 'listing_id is required'})
        
        cursor, connection = ConnectToDatabase()
        
        # Get listing payment data
        query = """
            SELECT 
                lp.payment_id,
                lp.listing_id,
                lp.buyer_id,
                u.FirstName as buyer_first_name,
                u.LastName as buyer_last_name,
                u.Email as buyer_email,
                l.user_id as seller_id,
                u2.FirstName as seller_first_name,
                u2.LastName as seller_last_name,
                u2.Email as seller_email,
                l.currency,
                l.amount,
                l.accept_currency,
                lp.buyer_paid_at,
                lp.seller_paid_at,
                lp.buyer_transaction_id,
                lp.seller_transaction_id,
                lp.payment_method,
                CASE 
                    WHEN lp.buyer_paid_at IS NOT NULL AND lp.seller_paid_at IS NOT NULL THEN 'completed'
                    WHEN lp.buyer_paid_at IS NOT NULL THEN 'buyer_paid'
                    WHEN lp.seller_paid_at IS NOT NULL THEN 'seller_paid'
                    ELSE 'pending'
                END as status,
                lp.created_at,
                lp.updated_at
            FROM listing_payments lp
            JOIN listings l ON lp.listing_id = l.listing_id
            JOIN users u ON lp.buyer_id = u.user_id
            JOIN users u2 ON l.user_id = u2.user_id
            WHERE lp.listing_id = %s
        """
        cursor.execute(query, (listing_id,))
        payments = cursor.fetchall()
        
        cursor.close()
        connection.close()
        
        return jsonify({
            'success': True,
            'listing_id': listing_id,
            'payments': payments,
            'count': len(payments) if payments else 0
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@blueprint.route('/Admin/GetPayPalTransactions', methods=['GET', 'POST'])
@cross_origin()
def get_paypal_transactions():
    """Get PayPal transactions, optionally filtered by listing or user"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        listing_id = params.get('listing_id')
        user_id = params.get('user_id')
        status = params.get('status')  # e.g., 'COMPLETED', 'PENDING', 'FAILED'
        limit = int(params.get('limit', 100))
        offset = int(params.get('offset', 0))
        
        cursor, connection = ConnectToDatabase()
        
        # Build query
        query = """
            SELECT 
                po.order_id,
                po.user_id,
                u.FirstName as user_first_name,
                u.LastName as user_last_name,
                u.Email as user_email,
                po.listing_id,
                l.currency,
                l.amount,
                po.transaction_id,
                po.status,
                po.payer_email,
                po.payer_name,
                po.amount as paypal_amount,
                po.currency as paypal_currency,
                po.created_at,
                po.updated_at
            FROM paypal_orders po
            JOIN users u ON po.user_id = u.user_id
            LEFT JOIN listings l ON po.listing_id = l.listing_id
            WHERE 1=1
        """
        
        query_params = []
        
        if listing_id:
            query += " AND po.listing_id = %s"
            query_params.append(listing_id)
        
        if user_id:
            query += " AND po.user_id = %s"
            query_params.append(user_id)
        
        if status:
            query += " AND po.status = %s"
            query_params.append(status)
        
        query += f" ORDER BY po.created_at DESC LIMIT {limit} OFFSET {offset}"
        
        cursor.execute(query, query_params)
        transactions = cursor.fetchall()
        
        # Get total count for pagination
        count_query = """
            SELECT COUNT(*) as total FROM paypal_orders po
            WHERE 1=1
        """
        count_params = []
        if listing_id:
            count_query += " AND po.listing_id = %s"
            count_params.append(listing_id)
        if user_id:
            count_query += " AND po.user_id = %s"
            count_params.append(user_id)
        if status:
            count_query += " AND po.status = %s"
            count_params.append(status)
        
        cursor.execute(count_query, count_params)
        count_result = cursor.fetchone()
        total_count = count_result['total'] if count_result else 0
        
        cursor.close()
        connection.close()
        
        return jsonify({
            'success': True,
            'transactions': transactions,
            'count': len(transactions) if transactions else 0,
            'total_count': total_count,
            'limit': limit,
            'offset': offset
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@blueprint.route('/Admin/GetPayPalTransactionById', methods=['GET', 'POST'])
@cross_origin()
def get_paypal_transaction_by_id():
    """Get detailed PayPal transaction info"""
    try:
        params = request.args.to_dict() if request.method == 'GET' else request.get_json()
        order_id = params.get('order_id')
        
        if not order_id:
            return jsonify({'success': False, 'error': 'order_id is required'})
        
        cursor, connection = ConnectToDatabase()
        
        query = """
            SELECT 
                po.order_id,
                po.user_id,
                u.FirstName as user_first_name,
                u.LastName as user_last_name,
                u.Email as user_email,
                po.listing_id,
                l.currency,
                l.amount as listing_amount,
                l.location,
                po.transaction_id,
                po.status,
                po.payer_email,
                po.payer_name,
                po.amount as paypal_amount,
                po.currency as paypal_currency,
                po.created_at,
                po.updated_at
            FROM paypal_orders po
            JOIN users u ON po.user_id = u.user_id
            LEFT JOIN listings l ON po.listing_id = l.listing_id
            WHERE po.order_id = %s
        """
        cursor.execute(query, (order_id,))
        transaction = cursor.fetchone()
        
        cursor.close()
        connection.close()
        
        if transaction:
            return jsonify({
                'success': True,
                'transaction': transaction
            })
        else:
            return jsonify({'success': False, 'error': 'Transaction not found'})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

