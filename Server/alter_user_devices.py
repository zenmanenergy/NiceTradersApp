#!/usr/bin/env python3

import pymysql
from _Lib import Database

# Connect to database
cursor, connection = Database.ConnectToDatabase()

try:
    # Alter the user_devices table to allow NULL device_token
    alter_query = "ALTER TABLE user_devices MODIFY device_token VARCHAR(500) NULL;"
    cursor.execute(alter_query)
    connection.commit()
    print("✓ user_devices table altered successfully - device_token can now be NULL")
    
except Exception as e:
    print(f"✗ Error altering table: {str(e)}")
finally:
    connection.close()
