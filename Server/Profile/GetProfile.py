from _Lib import Database
import json

def get_profile(SessionId):
	if not SessionId:
		return '{"success": false, "error": "Session ID required"}'
	
	cursor, connection = Database.ConnectToDatabase()
	
	try:
		# Get user ID from session
		session_query = """
			SELECT users.UserId, users.FirstName, users.LastName, users.Email, users.Phone, 
				   users.DateCreated, users.Location, users.Bio, users.Rating, users.TotalExchanges,
				   users.PreferredLanguage
			FROM usersessions 
			INNER JOIN users ON usersessions.UserId COLLATE utf8mb4_general_ci = users.UserId COLLATE utf8mb4_general_ci
			WHERE usersessions.SessionId COLLATE utf8mb4_general_ci = %s
		"""
		cursor.execute(session_query, (SessionId,))
		user_result = cursor.fetchone()
		
		if not user_result:
			connection.close()
			return '{"success": false, "error": "Invalid session"}'
		
		# Format the response
		profile_data = {
			"success": True,
			"profile": {
				"name": f"{user_result['FirstName']} {user_result['LastName']}",
				"email": user_result['Email'],
				"phone": user_result['Phone'] or '',
				"joinDate": user_result['DateCreated'].strftime('%B %d, %Y') if user_result['DateCreated'] else '',
				"rating": float(user_result['Rating']) if user_result['Rating'] else 0.0,
				"totalExchanges": int(user_result['TotalExchanges']) if user_result['TotalExchanges'] else 0,
				"location": user_result['Location'] or '',
				"bio": user_result['Bio'] or '',
				"preferredLanguage": user_result.get('PreferredLanguage', 'en') or 'en'
			}
		}
		
		connection.close()
		return json.dumps(profile_data)
		
	except Exception as e:
		connection.close()
		return f'{{"success": false, "error": "Database error: {str(e)}"}}'