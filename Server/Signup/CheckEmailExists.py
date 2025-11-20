from _Lib import Database

def check_email_exists(Email):
	if not Email:
		return '{"exists": false}'
	
	# Connect to the database
	cursor, connection = Database.ConnectToDatabase()

	try:
		# Check if email exists
		query = "SELECT COUNT(*) as count FROM users WHERE Email = %s"
		values = (Email,)
		cursor.execute(query, values)
		result = cursor.fetchone()
		
		# Close the database connection
		connection.close()
		
		# Return result
		exists = result['count'] > 0
		return f'{{"exists": {str(exists).lower()}}}'
		
	except Exception as e:
		connection.close()
		return f'{{"exists": false, "error": "{str(e)}"}}'