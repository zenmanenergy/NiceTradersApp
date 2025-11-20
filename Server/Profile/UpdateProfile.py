from _Lib import Database

def update_profile(SessionId, Name, Email, Phone, Location, Bio):
	if not SessionId:
		return '{"success": false, "error": "Session ID required"}'
	
	cursor, connection = Database.ConnectToDatabase()
	
	try:
		# Get user ID from session
		session_query = """
			SELECT users.UserId
			FROM usersessions 
			INNER JOIN users ON usersessions.UserId COLLATE utf8mb4_general_ci = users.UserId COLLATE utf8mb4_general_ci
			WHERE usersessions.SessionId COLLATE utf8mb4_general_ci = %s
		"""
		cursor.execute(session_query, (SessionId,))
		user_result = cursor.fetchone()
		
		if not user_result:
			connection.close()
			return '{"success": false, "error": "Invalid session"}'
		
		user_id = user_result['UserId']
		
		# Parse name into first and last name
		name_parts = Name.split(' ', 1) if Name else ['', '']
		first_name = name_parts[0] if len(name_parts) > 0 else ''
		last_name = name_parts[1] if len(name_parts) > 1 else ''
		
		# Update user profile
		update_query = """
			UPDATE users 
			SET FirstName = %s, LastName = %s, Email = %s, Phone = %s, Location = %s, Bio = %s
			WHERE UserId = %s
		"""
		cursor.execute(update_query, (first_name, last_name, Email, Phone, Location, Bio, user_id))
		connection.commit()
		
		connection.close()
		return '{"success": true, "message": "Profile updated successfully"}'
		
	except Exception as e:
		connection.close()
		return f'{{"success": false, "error": "Database error: {str(e)}"}}'