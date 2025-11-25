from _Lib import Database

def update_profile(SessionId, Name=None, Email=None, Phone=None, Location=None, Bio=None, PreferredLanguage=None):
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
		
		# Build dynamic update query based on provided fields
		update_fields = []
		update_values = []
		
		# Handle profile updates (only if provided)
		if Name:
			name_parts = Name.split(' ', 1)
			if name_parts:
				update_fields.append("FirstName = %s")
				update_values.append(name_parts[0])
				if len(name_parts) > 1:
					update_fields.append("LastName = %s")
					update_values.append(name_parts[1])
				else:
					update_fields.append("LastName = %s")
					update_values.append('')
		
		if Email:
			update_fields.append("Email = %s")
			update_values.append(Email)
		
		if Phone:
			update_fields.append("Phone = %s")
			update_values.append(Phone)
		
		if Location:
			update_fields.append("Location = %s")
			update_values.append(Location)
		
		if Bio:
			update_fields.append("Bio = %s")
			update_values.append(Bio)
		
		# Handle language preference
		if PreferredLanguage:
			# Validate language code (must be 2-5 characters)
			if len(PreferredLanguage) <= 5 and PreferredLanguage.isalnum():
				update_fields.append("PreferredLanguage = %s")
				update_values.append(PreferredLanguage)
			else:
				connection.close()
				return '{"success": false, "error": "Invalid language code"}'
		
		# Only update if there are fields to update
		if not update_fields:
			connection.close()
			return '{"success": false, "error": "No fields to update"}'
		
		# Add user ID to the values
		update_values.append(user_id)
		
		# Update user profile
		update_query = f"""
			UPDATE users 
			SET {', '.join(update_fields)}
			WHERE UserId = %s
		"""
		cursor.execute(update_query, update_values)
		connection.commit()
		
		connection.close()
		return '{"success": true, "message": "Profile updated successfully"}'
		
	except Exception as e:
		connection.close()
		return f'{{"success": false, "error": "Database error: {str(e)}"}}'