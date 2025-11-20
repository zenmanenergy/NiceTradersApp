from _Lib import Database
import json

def get_exchange_history(SessionId):
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
		
		# Get exchange history
		history_query = """
			SELECT ExchangeId, ExchangeDate, Currency, Amount, PartnerName, Rating, 
				   ExchangeType, Status, CreatedDate
			FROM exchange_history 
			WHERE UserId = %s 
			ORDER BY ExchangeDate DESC
			LIMIT 50
		"""
		cursor.execute(history_query, (user_id,))
		history_results = cursor.fetchall()
		
		# Format the response
		exchanges = []
		for exchange in history_results:
			exchanges.append({
				"id": exchange['ExchangeId'],
				"date": exchange['ExchangeDate'].strftime('%Y-%m-%d') if exchange['ExchangeDate'] else '',
				"currency": exchange['Currency'],
				"amount": float(exchange['Amount']) if exchange['Amount'] else 0,
				"partner": exchange['PartnerName'],
				"rating": int(exchange['Rating']) if exchange['Rating'] else 0,
				"type": exchange['ExchangeType'],
				"status": exchange['Status']
			})
		
		response_data = {
			"success": True,
			"exchanges": exchanges
		}
		
		connection.close()
		return json.dumps(response_data)
		
	except Exception as e:
		connection.close()
		return f'{{"success": false, "error": "Database error: {str(e)}"}}'