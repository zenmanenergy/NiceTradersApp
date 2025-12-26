from _Lib import Database
import uuid
import datetime

def verify_session(session_id):
	if not session_id:
		session_id = "-1"
	
	# Connect to the database
	cursor, connection = Database.ConnectToDatabase()

	# Construct the SQL query with COLLATE to fix collation mismatch
	query = """
		SELECT user_sessions.session_id, users.UserType 
		FROM user_sessions 
		INNER JOIN users ON user_sessions.user_id COLLATE utf8mb4_general_ci = users.user_id COLLATE utf8mb4_general_ci 
		WHERE user_sessions.session_id COLLATE utf8mb4_general_ci = %s
	"""
	values = (session_id,)


	# Execute the query and get the results
	cursor.execute(query, values)
	result = cursor.fetchone()
	# Close the database connection
	connection.close()
	
	if not result:
		return '""'
	else:
		return '{"session_id": "' + result["session_id"] + '", "UserType": "' + result["UserType"] + '"}'

