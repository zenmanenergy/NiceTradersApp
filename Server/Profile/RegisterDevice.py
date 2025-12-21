"""
Register or update a user's device token for push notifications
"""
from _Lib import Database
import uuid
import datetime
import os


def log_device_event(message):
	"""Log device registration events to a file"""
	log_file = '/tmp/device_registration.log'
	timestamp = datetime.datetime.now().isoformat()
	with open(log_file, 'a') as f:
		f.write(f"[{timestamp}] {message}\n")


def register_device(user_id, device_token, device_type='ios', device_name=None, app_version=None, os_version=None):
	"""
	Register or update a device token for a user
	
	Args:
		user_id: User ID
		device_token: The device token from APNs/Firebase (can be None initially)
		device_type: Type of device ('ios', 'android', or 'web')
		device_name: Optional device name (e.g., "iPhone 14")
		app_version: Optional app version
		os_version: Optional OS version
	
	Returns:
		JSON string with success status
	"""
	log_device_event(f"register_device called: user_id={user_id}, device_type={device_type}, device_token={device_token}, device_name={device_name}, app_version={app_version}, os_version={os_version}")
	
	if not user_id:
		log_device_event("ERROR: user_id is required")
		return '{"success": false, "error": "user_id is required"}'
	
	# Validate device type
	if device_type not in ['ios', 'android', 'web']:
		log_device_event(f"ERROR: Invalid device_type: {device_type}")
		return '{"success": false, "error": "Invalid device_type. Must be ios, android, or web"}'
	
	# Connect to the database
	cursor, connection = Database.ConnectToDatabase()
	
	try:
		if device_token:
			# Check if this device token already exists for this user
			query = "SELECT device_id FROM user_devices WHERE user_id = %s AND device_token = %s"
			values = (user_id, device_token)
			cursor.execute(query, values)
			existing_device = cursor.fetchone()
			
			if existing_device:
				# Update existing device
				update_query = """
					UPDATE user_devices 
					SET device_name = %s, app_version = %s, os_version = %s, 
					    is_active = 1, last_used_at = NOW(), updated_at = NOW()
					WHERE device_id = %s
				"""
				update_values = (device_name, app_version, os_version, existing_device['device_id'])
				cursor.execute(update_query, update_values)
			else:
				# Check if token already exists for another user (shouldn't happen but safeguard)
				check_query = "SELECT user_id FROM user_devices WHERE device_token = %s"
				cursor.execute(check_query, (device_token,))
				other_user = cursor.fetchone()
				
				if other_user and other_user['user_id'] != user_id:
					# Token belongs to another user, remove it from there first
					delete_query = "DELETE FROM user_devices WHERE device_token = %s"
					cursor.execute(delete_query, (device_token,))
				
				# Insert new device
				device_id = "DEV" + str(uuid.uuid4())
				insert_query = """
					INSERT INTO user_devices 
					(device_id, user_id, device_type, device_token, device_name, app_version, os_version, is_active, registered_at)
					VALUES (%s, %s, %s, %s, %s, %s, %s, 1, NOW())
				"""
				insert_values = (device_id, user_id, device_type, device_token, device_name, app_version, os_version)
				cursor.execute(insert_query, insert_values)
		else:
			# No device token yet - register device with pending token
			# First check if this user already has a pending device entry for this device type
			query = "SELECT device_id FROM user_devices WHERE user_id = %s AND device_type = %s AND device_token IS NULL"
			values = (user_id, device_type)
			cursor.execute(query, values)
			existing_device = cursor.fetchone()
			
			if existing_device:
				# Update the existing pending device
				update_query = """
					UPDATE user_devices 
					SET device_name = %s, app_version = %s, os_version = %s, 
					    last_used_at = NOW(), updated_at = NOW()
					WHERE device_id = %s
				"""
				update_values = (device_name, app_version, os_version, existing_device['device_id'])
				cursor.execute(update_query, update_values)
			else:
				# Create new device entry with pending token
				device_id = "DEV" + str(uuid.uuid4())
				insert_query = """
					INSERT INTO user_devices 
					(device_id, user_id, device_type, device_token, device_name, app_version, os_version, is_active, registered_at)
					VALUES (%s, %s, %s, NULL, %s, %s, %s, 1, NOW())
				"""
				insert_values = (device_id, user_id, device_type, device_name, app_version, os_version)
				cursor.execute(insert_query, insert_values)
		
		connection.commit()
		connection.close()
		
		log_device_event(f"SUCCESS: Device registered for user {user_id}")
		return '{"success": true, "message": "Device registered successfully"}'
		
	except Exception as e:
		connection.close()
		log_device_event(f"ERROR: Database error for user {user_id}: {str(e)}")
		import traceback
		log_device_event(f"Traceback: {traceback.format_exc()}")
		return f'{{"success": false, "error": "Database error: {str(e)}"}}'
