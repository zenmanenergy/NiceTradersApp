# Database Connection Instructions

## Quick Reference for Running SQL Queries

### Database Credentials
- **Host:** localhost
- **User:** stevenelson
- **Password:** mwitcitw711
- **Database:** nicetraders

### Connection Setup
The project uses PyMySQL (not mysql-connector). Always use the virtual environment.

### How to Run SQL Scripts

**Method 1: Direct Python Script (Recommended)**
```bash
cd /Users/stevenelson/Documents/GitHub/NiceTradersApp/Server
source venv/bin/activate
python << 'EOF'
import pymysql

db = pymysql.connect(
    host='localhost',
    user='stevenelson',
    password='mwitcitw711',
    database='nicetraders'
)
cursor = db.cursor()

# Your SQL here
cursor.execute("SELECT * FROM users LIMIT 5")
results = cursor.fetchall()
for row in results:
    print(row)

db.commit()
cursor.close()
db.close()
EOF
```

**Method 2: SQL File Execution**
```bash
cd /Users/stevenelson/Documents/GitHub/NiceTradersApp/Server
source venv/bin/activate
python << 'EOF'
import pymysql

db = pymysql.connect(
    host='localhost',
    user='stevenelson',
    password='mwitcitw711',
    database='nicetraders'
)
cursor = db.cursor()

with open('path/to/file.sql', 'r', encoding='utf-8') as f:
    sql_script = f.read()

# Split and execute statements
statements = [s.strip() for s in sql_script.split(';') if s.strip() and not s.strip().startswith('--')]
for statement in statements:
    if statement:
        cursor.execute(statement)

db.commit()
cursor.close()
db.close()
EOF
```

### Common Mistakes to Avoid
1. ❌ Don't use `mysql.connector` - it's not installed
2. ❌ Don't use `root` user with `root` password - wrong credentials
3. ❌ Don't forget to activate venv first
4. ✅ Always use PyMySQL library
5. ✅ Always use credentials from `_Lib/Database.py`

### Virtual Environment
- **Location:** `/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server/venv`
- **Activation:** `source venv/bin/activate`
- **Python Library:** PyMySQL (already installed)

### Reference File
The canonical database connection code is in:
```
/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server/_Lib/Database.py
```

Always check this file for current credentials if connection fails.

### Running Migrations
All migration files should be placed in:
```
/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server/migrations/
```

Use the Method 2 template above to execute them.
