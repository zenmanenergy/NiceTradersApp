from _Lib import Database
import uuid
import datetime
import hashlib

def get_login(Email, Password):
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
			query = "DELETE FROM usersessions WHERE UserId = %s"
			values = (result['UserId'],)
			cursor.execute(query, values)
			connection.commit()

			# Create a new session
			SessionId = "SES" + str(uuid.uuid4())
			query = "INSERT INTO usersessions(SessionId, UserId, DateAdded) VALUES (%s, %s, %s)"
			values = (SessionId, result['UserId'], datetime.datetime.now(),)
			cursor.execute(query, values)
			connection.commit()

			# Close the database connection
			connection.close()

			# Return success with session data
			return f'{{"SessionId": "{SessionId}", "UserType": "{result["UserType"]}"}}'
			
	except Exception as e:
		connection.close()
		return f'{{"success": false, "error": "Database error: {str(e)}"}}'
