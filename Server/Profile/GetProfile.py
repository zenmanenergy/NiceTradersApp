from _Lib import Database
import json

def get_profile(SessionId):
	if not SessionId:
		return '{"success": false, "error": "Session ID required"}'
	
	cursor, connection = Database.ConnectToDatabase()
	
	try:
		# Get user ID from session
		session_query = """
			SELECT users.user_id, users.FirstName, users.LastName, users.Email, users.Phone, 
				   users.DateCreated, users.Location, users.Bio, users.Rating, users.TotalExchanges,
				   users.PreferredLanguage
			FROM usersessions 
			INNER JOIN users ON usersessions.user_id COLLATE utf8mb4_general_ci = users.user_id COLLATE utf8mb4_general_ci
			WHERE usersessions.SessionId COLLATE utf8mb4_general_ci = %s
		"""
		cursor.execute(session_query, (SessionId,))
		user_result = cursor.fetchone()
		
		if not user_result:
			connection.close()
			return '{"success": false, "error": "Invalid session"}'
		
		# Get completed exchanges count
		user_id = user_result['user_id']
		completed_query = """
			SELECT COUNT(DISTINCT l.listing_id) as count
			FROM listings l
			JOIN listing_meeting_time lmt ON l.listing_id = lmt.listing_id
			WHERE (l.user_id = %s OR lmt.buyer_id = %s)
			AND l.status = 'completed'
		"""
		cursor.execute(completed_query, (user_id, user_id))
		completed_result = cursor.fetchone()
		completed_exchanges = completed_result['count'] if completed_result else 0
		
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
				"completedExchanges": int(completed_exchanges) if completed_exchanges else 0,
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