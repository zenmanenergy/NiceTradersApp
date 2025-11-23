"""
Pytest configuration and fixtures for NiceTradersApp tests
"""
import pytest
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from flask_app import app
import pymysql
from _Lib import Database

@pytest.fixture
def client():
    """Create a test client for the Flask app"""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

@pytest.fixture
def db_connection():
    """Create a database connection for tests"""
    cursor, connection = Database.ConnectToDatabase()
    yield cursor, connection
    connection.close()

@pytest.fixture
def test_user(db_connection):
    """Create a test user and return user ID and session ID"""
    cursor, connection = db_connection
    
    # Create test user
    import uuid
    import bcrypt
    from tests.test_utils import generate_uuid
    
    user_id = generate_uuid('USR')
    email = f"test_{uuid.uuid4().hex[:8]}@example.com"
    password = bcrypt.hashpw("TestPassword123".encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
    
    cursor.execute("""
        INSERT INTO users (UserId, FirstName, LastName, Email, Password, UserType, IsActive)
        VALUES (%s, %s, %s, %s, %s, %s, %s)
    """, (user_id, "Test", "User", email, password, "standard", 1))
    
    # Create session
    session_id = generate_uuid('SES')
    cursor.execute("""
        INSERT INTO usersessions (SessionId, UserId)
        VALUES (%s, %s)
    """, (session_id, user_id))
    
    connection.commit()
    
    yield {
        'user_id': user_id,
        'session_id': session_id,
        'email': email,
        'password': 'TestPassword123'
    }
    
    # Cleanup
    cursor.execute("DELETE FROM usersessions WHERE UserId = %s", (user_id,))
    cursor.execute("DELETE FROM users WHERE UserId = %s", (user_id,))
    connection.commit()

@pytest.fixture
def test_listing(db_connection, test_user):
    """Create a test listing"""
    cursor, connection = db_connection
    
    import uuid
    from datetime import datetime, timedelta
    from tests.test_utils import generate_uuid
    
    listing_id = generate_uuid('LST')
    user_id = test_user['user_id']
    available_until = (datetime.now() + timedelta(days=30)).strftime('%Y-%m-%d %H:%M:%S')
    
    cursor.execute("""
        INSERT INTO listings (
            listing_id, user_id, currency, amount, accept_currency,
            location, latitude, longitude, location_radius, meeting_preference,
            available_until, status
        ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    """, (listing_id, user_id, 'USD', 1000.00, 'EUR', 
          'San Francisco, CA', 37.7749, -122.4194, 10, 'public', 
          available_until, 'active'))
    
    connection.commit()
    
    yield {
        'listing_id': listing_id,
        'user_id': user_id,
        'currency': 'USD',
        'amount': 1000.00,
        'accept_currency': 'EUR'
    }
    
    # Cleanup
    cursor.execute("DELETE FROM listings WHERE listing_id = %s", (listing_id,))
    connection.commit()
