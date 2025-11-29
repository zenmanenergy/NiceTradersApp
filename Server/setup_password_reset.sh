#!/bin/bash

# Script to set up password reset tokens table
# This script runs the migration to create the password_reset_tokens table

set -e

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Activate virtual environment
echo "Activating virtual environment..."
if [ -d "$SCRIPT_DIR/venv" ]; then
    source "$SCRIPT_DIR/venv/bin/activate"
elif [ -d "$SCRIPT_DIR/.venv" ]; then
    source "$SCRIPT_DIR/.venv/bin/activate"
else
    echo "Error: Virtual environment not found at $SCRIPT_DIR/venv or $SCRIPT_DIR/.venv"
    exit 1
fi

echo "Running password reset tokens table migration..."

# Run the SQL migration
python3 -c "
import pymysql
import os

# Database connection details
db_config = {
    'host': 'localhost',
    'user': 'stevenelson',
    'password': 'mwitcitw711',
    'database': 'nicetraders'
}

try:
    # Connect to database
    db = pymysql.connect(**db_config)
    cursor = db.cursor()
    
    # Read and execute the migration file
    migration_file = os.path.join('$SCRIPT_DIR', 'migrations', '004_password_reset_tokens.sql')
    
    with open(migration_file, 'r') as f:
        sql_content = f.read()
    
    # Execute each statement
    for statement in sql_content.split(';'):
        statement = statement.strip()
        if statement:
            cursor.execute(statement)
    
    db.commit()
    
    print('✓ password_reset_tokens table created successfully!')
    print('✓ Migration completed')
    
except pymysql.Error as e:
    print(f'✗ Database error: {e}')
    exit(1)
except FileNotFoundError as e:
    print(f'✗ Migration file not found: {e}')
    exit(1)
except Exception as e:
    print(f'✗ Error: {e}')
    exit(1)
finally:
    if 'cursor' in locals():
        cursor.close()
    if 'db' in locals():
        db.close()
"

echo "✓ Setup complete!"

