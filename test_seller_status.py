import sys
sys.path.insert(0, '/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server')

import pymysql
import pymysql.cursors
from Dashboard.GetUserDashboard import get_user_dashboard
import json

seller_user_id = 'USRf62cb55a-8b3b-4b84-8127-943e0e16bad6'

db = pymysql.connect(
    host='localhost',
    user='stevenelson',
    password='mwitcitw711',
    database='nicetraders',
    cursorclass=pymysql.cursors.DictCursor
)
cursor = db.cursor()
cursor.execute("SELECT SessionId FROM usersessions WHERE user_id = %s LIMIT 1", (seller_user_id,))
session = cursor.fetchone()
db.close()

if session:
    print(f"[TEST] Seller session found: {session['SessionId']}")
    result = get_user_dashboard(session['SessionId'])
    data = json.loads(result)
    print(f"[TEST] API success: {data['success']}")
    if data['success']:
        for ex in data['data']['activeExchanges']:
            print(f"[TEST] Seller displayStatus: {ex.get('displayStatus')}")
else:
    print("[TEST] No session found for seller")
