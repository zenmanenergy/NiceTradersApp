from _Lib import Database
import uuid
import datetime

def verify_session(SessionId):
	if not SessionId:
		SessionId = "-1"
	
	# Connect to the database
	cursor, connection = Database.ConnectToDatabase()

	# Construct the SQL query with COLLATE to fix collation mismatch
	query = """
		SELECT usersessions.SessionId, users.UserType 
		FROM usersessions 
		INNER JOIN users ON usersessions.user_id COLLATE utf8mb4_general_ci = users.user_id COLLATE utf8mb4_general_ci 
		WHERE usersessions.SessionId COLLATE utf8mb4_general_ci = %s
	"""
	values = (SessionId,)


	# Execute the query and get the results
	cursor.execute(query, values)
	result = cursor.fetchone()
	# Close the database connection
	connection.close()
	
	if not result:
		return '""'
	else:
		return '{"SessionId": "' + result["SessionId"] + '", "UserType": "' + result["UserType"] + '"}'

