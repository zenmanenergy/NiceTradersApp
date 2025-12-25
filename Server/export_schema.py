#!/usr/bin/env python3
import pymysql
import os
from datetime import datetime

# Database connection details
db = pymysql.connect(
    host='localhost',
    user='stevenelson',
    password='mwitcitw711',
    database='nicetraders'
)

cursor = db.cursor()

# Get all tables
cursor.execute("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='nicetraders'")
tables = cursor.fetchall()

# Build schema file
schema_content = f"-- Database Schema Export\n-- Exported: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n"

for (table_name,) in tables:
    # Get CREATE TABLE statement
    cursor.execute(f"SHOW CREATE TABLE `{table_name}`")
    result = cursor.fetchone()
    create_statement = result[1]
    
    schema_content += f"{create_statement};\n\n"

# Write to file
script_dir = os.path.dirname(os.path.abspath(__file__))
output_path = os.path.join(script_dir, "database_schema.sql")
with open(output_path, 'w') as f:
    f.write(schema_content)

print(f"✅ Schema exported to {output_path}")
print(f"📊 Total tables: {len(tables)}")

cursor.close()
db.close()
