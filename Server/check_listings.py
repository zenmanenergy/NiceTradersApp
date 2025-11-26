import pymysql

db = pymysql.connect(
    host='localhost',
    user='stevenelson',
    password='mwitcitw711',
    database='nicetraders'
)
cursor = db.cursor(pymysql.cursors.DictCursor)

cursor.execute("SELECT listing_id, currency, accept_currency, amount, status FROM listings WHERE status = 'active' LIMIT 10")
results = cursor.fetchall()

print("\n=== Active Listings ===")
for row in results:
    print(f"ID: {row['listing_id']}")
    print(f"  Has: {row['currency']} (amount: {row['amount']})")
    print(f"  Wants: {row['accept_currency']}")
    print(f"  Status: {row['status']}")
    print()

cursor.close()
db.close()
