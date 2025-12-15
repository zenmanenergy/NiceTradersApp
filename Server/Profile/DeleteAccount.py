from _Lib import Database

def delete_account(SessionId):
	if not SessionId:
		return '{"success": false, "error": "Session ID required"}'
	
	cursor, connection = Database.ConnectToDatabase()
	
	try:
		# Get user ID from session
		session_query = """
			SELECT users.user_id
			FROM usersessions 
			INNER JOIN users ON usersessions.user_id COLLATE utf8mb4_general_ci = users.user_id COLLATE utf8mb4_general_ci
			WHERE usersessions.SessionId COLLATE utf8mb4_general_ci = %s
		"""
		cursor.execute(session_query, (SessionId,))
		user_result = cursor.fetchone()
		
		if not user_result:
			connection.close()
			return '{"success": false, "error": "Invalid session"}'
		
		user_id = user_result['user_id']
		
		# Delete related data first (foreign key constraints)
		# Delete user sessions
		cursor.execute("DELETE FROM usersessions WHERE user_id = %s", (user_id,))
		
		# Delete user settings
		cursor.execute("DELETE FROM user_settings WHERE user_id = %s", (user_id,))
		
		# Delete user listings (if any) - listings table uses lowercase user_id
		cursor.execute("DELETE FROM listings WHERE user_id = %s", (user_id,))
		
		# Finally delete the user
		cursor.execute("DELETE FROM users WHERE user_id = %s", (user_id,))
		
		connection.commit()
		connection.close()
		
		return '{"success": true, "message": "Account deleted successfully"}'
		
	except Exception as e:
		connection.close()
		return f'{{"success": false, "error": "Database error: {str(e)}"}}'