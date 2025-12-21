from _Lib import Database
import uuid
import datetime
import hashlib
from Profile.RegisterDevice import register_device
import json

def get_login(Email, Password, device_token=None, device_type='ios', device_name=None, app_version=None, os_version=None):
	if not Email or not Password:
		return '{"success": false, "error": "Email and password are required"}'
	
	# Connect to the database
	cursor, connection = Database.ConnectToDatabase()

	try:
		# Hash the password to match signup process
		hashed_password = hashlib.sha256(Password.encode()).hexdigest()

		# Construct the SQL query
		query = "SELECT * FROM users WHERE Email = %s AND Password = %s AND IsActive = 1"
		values = (Email, hashed_password,)

		print(query % tuple(map(repr, values)))

		# Execute the query and get the results
		cursor.execute(query, values)
		result = cursor.fetchone()

		if not result:
			connection.close()
			return '{"success": false, "error": "Invalid email or password"}'
		else:
			print(result)
			# Delete existing sessions for the user
			query = "DELETE FROM usersessions WHERE user_id = %s"
			values = (result['user_id'],)
			cursor.execute(query, values)
			connection.commit()

			# Create a new session
			SessionId = "SES" + str(uuid.uuid4())
			query = "INSERT INTO usersessions(SessionId, user_id, DateAdded) VALUES (%s, %s, %s)"
			values = (SessionId, result['user_id'], datetime.datetime.now(),)
			cursor.execute(query, values)
			connection.commit()

			# Close the database connection
			connection.close()
			
			# Always register device (token may be None initially, will be updated when APNs provides it)
			from Profile.RegisterDevice import log_device_event
			log_device_event(f"LOGIN: Registering device for user {result['user_id']} with device_type={device_type}, device_name={device_name}, app_version={app_version}, os_version={os_version}, device_token={device_token}")
			register_device(result['user_id'], device_token, device_type, device_name, app_version, os_version)

			# Return success with session data and user ID
			return f'{{"SessionId": "{SessionId}", "UserType": "{result["UserType"]}", "user_id": "{result["user_id"]}"}}'
			
	except Exception as e:
		connection.close()
		return f'{{"success": false, "error": "Database error: {str(e)}"}}'
