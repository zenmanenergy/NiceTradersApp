
# Add a comment
import json
import pymysql
import pymysql.cursors
from pymysql.constants import CLIENT



# Add a comment
def ConnectToDatabase():
	
	# Add a comment
	endpoint="localhost"
	username="steve"
	password="Lz7#YxRMMdb8"
	databaseName="nicetraders"
	
	# Add a comment
	Connection=pymysql.connect(host=endpoint,user=username, password=password, database = databaseName, cursorclass=pymysql.cursors.DictCursor, client_flag= CLIENT.MULTI_STATEMENTS)

	# Add a comment
	Cursor = Connection.cursor()

	# Add a comment
	return Cursor,Connection



ConnectToDatabase()
 