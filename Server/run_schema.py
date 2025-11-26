#!/usr/bin/env python3
"""
Script to create/alter tables in the NiceTradersApp database
"""
import pymysql
import pymysql.cursors
from pymysql.constants import CLIENT
import sys

def connect_to_database():
    """Connect to the MySQL database"""
    endpoint = "localhost"
    username = "root"
    password = "L@miaafm33!!"
    database_name = "nicetraders"
    
    try:
        connection = pymysql.connect(
            host=endpoint,
            user=username,
            password=password,
            database=database_name,
            cursorclass=pymysql.cursors.DictCursor,
            client_flag=CLIENT.MULTI_STATEMENTS
        )
        return connection
    except Exception as e:
        print(f"Failed to connect to database: {e}")
        sys.exit(1)

def execute_schema_file(schema_file):
    """Execute SQL schema file"""
    connection = connect_to_database()
    cursor = connection.cursor()
    
    try:
        # Read the schema file
        with open(schema_file, 'r') as f:
            schema = f.read()
        
        # Split by semicolon and execute each statement
        statements = schema.split(';')
        
        for i, statement in enumerate(statements):
            statement = statement.strip()
            if statement:  # Skip empty statements
                try:
                    print(f"Executing statement {i+1}...")
                    cursor.execute(statement)
                    connection.commit()
                    print(f"✓ Statement {i+1} executed successfully")
                except Exception as e:
                    print(f"✗ Error in statement {i+1}: {e}")
                    # Continue with next statement instead of failing
                    connection.rollback()
        
        cursor.close()
        connection.close()
        print("\n✓ Schema update completed!")
        
    except Exception as e:
        print(f"Error reading or executing schema: {e}")
        sys.exit(1)

if __name__ == "__main__":
    schema_file = "database_schema.sql"
    print(f"Running schema from {schema_file}...")
    execute_schema_file(schema_file)
