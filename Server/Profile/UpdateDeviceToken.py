"""
Update a device token for a user after APNs provides it
This is called asynchronously after the initial login/signup
"""
from _Lib import Database
import json


def update_device_token(user_id, device_type, device_token, app_version=None, os_version=None):
	"""
	Update the device token for a user's device
	Called after APNs provides the token asynchronously
	
	Args:
		user_id: User ID
		device_type: Type of device ('ios', 'android', or 'web')
		device_token: The device token from APNs/Firebase
		app_version: Optional app version to update
		os_version: Optional OS version to update
	
	Returns:
		JSON string with success status
	"""
	if not user_id or not device_token:
		return '{"success": false, "error": "user_id and device_token are required"}'
	
	if device_type not in ['ios', 'android', 'web']:
		return '{"success": false, "error": "Invalid device_type"}'
	
	# Connect to the database
	cursor, connection = Database.ConnectToDatabase()
	
	try:
		# Check if this exact token already exists for this user
		query = "SELECT device_id FROM user_devices WHERE UserId = %s AND device_token = %s"
		cursor.execute(query, (user_id, device_token))
		existing = cursor.fetchone()
		
		if existing:
			# Token already registered for this user, just update timestamp and version info
			update_query = """
				UPDATE user_devices 
				SET last_used_at = NOW(), updated_at = NOW()
			"""
			update_params = []
			
			# Add app_version if provided
			if app_version is not None:
				update_query = update_query.rstrip() + ", app_version = %s"
				update_params.append(app_version)
			
			# Add os_version if provided
			if os_version is not None:
				update_query = update_query.rstrip() + ", os_version = %s"
				update_params.append(os_version)
			
			update_query += " WHERE device_id = %s"
			update_params.append(existing['device_id'])
			
			cursor.execute(update_query, tuple(update_params))
			connection.commit()
			connection.close()
			return '{"success": true, "message": "Device token already registered"}'
		
		# Check if token exists for another user
		check_query = "SELECT UserId FROM user_devices WHERE device_token = %s"
		cursor.execute(check_query, (device_token,))
		other_user = cursor.fetchone()
		
		if other_user and other_user['UserId'] != user_id:
			# Token is being reassigned to a different user - remove from old user
			delete_query = "DELETE FROM user_devices WHERE device_token = %s"
			cursor.execute(delete_query, (device_token,))
		
		# Find the pending device entry for this user with same device type
		pending_query = "SELECT device_id FROM user_devices WHERE UserId = %s AND device_type = %s AND device_token IS NULL"
		cursor.execute(pending_query, (user_id, device_type))
		pending_device = cursor.fetchone()
		
		if pending_device:
			# Update the pending device with the new token and version info
			update_query = """
				UPDATE user_devices 
				SET device_token = %s, updated_at = NOW()
			"""
			update_params = [device_token]
			
			# Add app_version if provided
			if app_version is not None:
				update_query = update_query.rstrip() + ", app_version = %s"
				update_params.append(app_version)
			
			# Add os_version if provided
			if os_version is not None:
				update_query = update_query.rstrip() + ", os_version = %s"
				update_params.append(os_version)
			
			update_query += " WHERE device_id = %s"
			update_params.append(pending_device['device_id'])
			
			cursor.execute(update_query, tuple(update_params))
		else:
			# No pending device found, this is an update to an existing device
			# Try to find any device of the same type for this user
			existing_query = "SELECT device_id FROM user_devices WHERE UserId = %s AND device_type = %s LIMIT 1"
			cursor.execute(existing_query, (user_id, device_type))
			existing_device = cursor.fetchone()
			
			if existing_device:
				# Update existing device with token and version info
				update_query = """
					UPDATE user_devices 
					SET device_token = %s, updated_at = NOW()
				"""
				update_params = [device_token]
				
				# Add app_version if provided
				if app_version is not None:
					update_query = update_query.rstrip() + ", app_version = %s"
					update_params.append(app_version)
				
				# Add os_version if provided
				if os_version is not None:
					update_query = update_query.rstrip() + ", os_version = %s"
					update_params.append(os_version)
				
				update_query += " WHERE device_id = %s"
				update_params.append(existing_device['device_id'])
				
				cursor.execute(update_query, tuple(update_params))
			else:
				# This shouldn't happen - no device entry exists, but handle it anyway
				# This means user logged in without device info, just update generic entry
				update_query = "UPDATE user_devices SET device_token = %s WHERE UserId = %s AND device_type = %s"
				cursor.execute(update_query, (device_token, user_id, device_type))
		
		connection.commit()
		connection.close()
		
		return '{"success": true, "message": "Device token updated successfully"}'
		
	except Exception as e:
		connection.close()
		return f'{{"success": false, "error": "Database error: {str(e)}"}}'
