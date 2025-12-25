from _Lib import Database
import json

def update_settings(SessionId, SettingsJson):
	if not SessionId:
		return '{"success": false, "error": "Session ID required"}'
	
	cursor, connection = Database.ConnectToDatabase()
	
	try:
		# Get user ID from session
		session_query = """
			SELECT users.user_id
			FROM user_sessions 
			INNER JOIN users ON user_sessions.user_id COLLATE utf8mb4_general_ci = users.user_id COLLATE utf8mb4_general_ci
			WHERE user_sessions.session_id COLLATE utf8mb4_general_ci = %s
		"""
		cursor.execute(session_query, (SessionId,))
		user_result = cursor.fetchone()
		
		if not user_result:
			connection.close()
			return '{"success": false, "error": "Invalid session"}'
		
		user_id = user_result['user_id']
		
		# Check if settings record exists
		check_query = "SELECT COUNT(*) as count FROM user_settings WHERE user_id = %s"
		cursor.execute(check_query, (user_id,))
		exists = cursor.fetchone()['count'] > 0
		
		if exists:
			# Update existing settings
			update_query = "UPDATE user_settings SET SettingsJson = %s WHERE user_id = %s"
			cursor.execute(update_query, (SettingsJson, user_id))
		else:
			# Insert new settings
			insert_query = "INSERT INTO user_settings (user_id, SettingsJson) VALUES (%s, %s)"
			cursor.execute(insert_query, (user_id, SettingsJson))
		
		connection.commit()
		connection.close()
		
		return '{"success": true, "message": "Settings updated successfully"}'
		
	except Exception as e:
		connection.close()
		return f'{{"success": false, "error": "Database error: {str(e)}"}}'