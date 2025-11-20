from _Lib import Database
import uuid
import datetime
import hashlib

def create_account(FirstName, LastName, Email, Phone, Password):
	# Validate required fields
	if not FirstName or not LastName or not Email or not Phone or not Password:
		return '{"success": false, "error": "All fields are required"}'
	
	# Connect to the database
	cursor, connection = Database.ConnectToDatabase()

	try:
		# Check if email already exists
		query = "SELECT COUNT(*) as count FROM users WHERE Email = %s"
		values = (Email,)
		cursor.execute(query, values)
		result = cursor.fetchone()
		
		if result['count'] > 0:
			connection.close()
			return '{"success": false, "error": "Email already exists"}'

		# Hash the password (in production, use bcrypt or similar)
		hashed_password = hashlib.sha256(Password.encode()).hexdigest()

		# Generate unique UserId
		UserId = "USR" + str(uuid.uuid4())
		
		# Insert new user
		query = """INSERT INTO users (UserId, FirstName, LastName, Email, Phone, Password, UserType, DateCreated, IsActive) 
				   VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)"""
		values = (
			UserId, 
			FirstName, 
			LastName, 
			Email, 
			Phone, 
			hashed_password, 
			'standard',  # Default user type
			datetime.datetime.now(),
			1  # Active by default
		)
		
		cursor.execute(query, values)
		connection.commit()
		
		# Create initial session for the new user
		SessionId = "SES" + str(uuid.uuid4())
		query = "INSERT INTO usersessions(SessionId, UserId, DateAdded) VALUES (%s, %s, %s)"
		values = (SessionId, UserId, datetime.datetime.now())
		cursor.execute(query, values)
		connection.commit()
		
		# Close the database connection
		connection.close()
		
		# Return success with session
		return f'{{"success": true, "sessionId": "{SessionId}", "userType": "standard"}}'
		
	except Exception as e:
		connection.close()
		return f'{{"success": false, "error": "Database error: {str(e)}"}}'