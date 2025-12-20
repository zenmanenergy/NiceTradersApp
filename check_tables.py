import pymysql

db = pymysql.connect(host='localhost', user='stevenelson', password='mwitcitw711', database='nicetraders')
cursor = db.cursor()
cursor.execute("SHOW TABLES")
tables = cursor.fetchall()
print("Tables in nicetraders database:")
for table in tables:
    print(f"  - {table[0]}")
cursor.close()
db.close()
