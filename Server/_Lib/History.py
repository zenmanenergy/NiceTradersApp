
# Add a comment
from .Database import ConnectToDatabase
import json
import uuid
import pymysql
import pymysql.cursors
from pymysql.constants import CLIENT
import datetime
import pytz



def LastModified(Table, KeyName,KeyValue ):
	# Add a comment
	Cursor,Connection=ConnectToDatabase()
	if KeyValue:
	
		# Construct the SQL query
		query = "SELECT TableName,max(DateAdded) LastModified,users.UserId,users.FirstName, users.LastName from history join users on users.UserId=history.UserId WHERE TableName = %s and KeyName = %s and KeyValue = %s"
		values = (Table, KeyName, KeyValue)
	else:
		query = "SELECT TableName,max(DateAdded) LastModified,users.UserId,users.FirstName, users.LastName from history join users on users.UserId=history.UserId WHERE TableName = %s and KeyName = %s group by %s"
		values = (Table, KeyName , KeyName)

	# Execute the query and get the results
	Cursor.execute(query, values)
	result = Cursor.fetchone()

	# Add a comment
	Connection.close()
	
	# Add a comment
	return result
	


def LastModifiedArray(Data):
	# Add a comment
	Cursor,Connection=ConnectToDatabase()
	
	Response=[]
	for key in Data:
		# Construct the SQL query
		query = "SELECT TableName,max(DateAdded) LastModified,users.UserId,users.FirstName, users.LastName from history join users on users.UserId=history.UserId WHERE TableName = %s and KeyName = %s and KeyValue = %s"
		values = (key.get("Table"),key.get("KeyName"),key.get("KeyValue"))

		print(query % tuple(map(repr, values)))
		# # Execute the query and get the results
		Cursor.execute(query, values)
		result = Cursor.fetchone()
		print("result",result)
		print("length",len(result))
		if result["LastModified"]:
			Response.append(result)
		
		# # Add a comment
	Connection.close()
	
	sorted_Response = sorted(Response, key=lambda x: x['LastModified'], reverse=True)
	
	return sorted_Response

def SaveHistory(Data, Table, KeyName,KeyValue ):
	# Add a comment
	Cursor,Connection=ConnectToDatabase()
	
	if not KeyValue:
		KeyValue=Data['KeyName']

	# Construct the SQL query
	SessionId=Data['SessionId']
	if SessionId=="ImportData":
		UserId="1"
	else:
		query = f"SELECT UserId from usersessions WHERE SessionId = '{SessionId}'"
		
		# print(query)

		# Execute the query and get the results
		Cursor.execute(query)
		result = Cursor.fetchone()
		if not result:
			return False
		UserId=result["UserId"]

	gmt_tz = pytz.timezone('GMT')
	now = datetime.datetime.now(gmt_tz)
	# print(now)
	now_str = now.strftime('%Y-%m-%d %H:%M:%S')
	historyId="HIS"+str(uuid.uuid4())
	query="INSERT into history (historyId, TableName, KeyName, KeyValue,UserId,  Data,DateAdded) VALUES (%s,%s,%s,%s,%s,%s,%s)"
	values=(historyId, Table, KeyName, KeyValue, UserId, json.dumps(Data),now_str)
	
	# print(query % tuple(map(repr, values)))
	# Add a comment
	Cursor.execute(query,values)
	
	# Add a comment
	Connection.commit()
	
	# Add a comment
	Cursor.close()
	
	# Add a comment
	Connection.close()
	
	# Add a comment
	return True
	