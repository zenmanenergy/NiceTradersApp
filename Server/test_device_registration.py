#!/usr/bin/env python3
"""
Test script to verify device token registration flow
"""

from Profile.RegisterDevice import register_device
from Profile.UpdateDeviceToken import update_device_token
from _Lib import Database
import json
import hashlib
import datetime
import uuid

def setup_test_user():
    """Create a test user for testing"""
    test_user_id = "USR-test-device-registration-00001"
    
    cursor, connection = Database.ConnectToDatabase()
    try:
        # Check if test user exists
        cursor.execute("SELECT user_id FROM users WHERE user_id = %s", (test_user_id,))
        if not cursor.fetchone():
            # Create test user
            hashed_password = hashlib.sha256("TestPassword123".encode()).hexdigest()
            cursor.execute(
                "INSERT INTO users (user_id, FirstName, LastName, Email, Phone, Password, UserType, DateCreated, IsActive) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)",
                (test_user_id, "Test", "User", "test.device@example.com", "555-0100", hashed_password, "standard", datetime.datetime.now(), 1)
            )
            connection.commit()
            print("✓ Test user created")
        else:
            print("✓ Test user already exists")
    finally:
        connection.close()
    
    return test_user_id

def test_device_registration():
    """Test the complete device registration flow"""
    
    print("\n" + "="*70)
    print("Device Token Registration Flow Test")
    print("="*70)
    
    # Create test user first
    cursor, connection = Database.ConnectToDatabase()
    test_user_id = "USR-test-device-registration-00001"
    
    try:
        # Check if test user exists
        cursor.execute("SELECT user_id FROM users WHERE user_id = %s", (test_user_id,))
        if not cursor.fetchone():
            # Create test user
            import hashlib
            import datetime
            hashed_password = hashlib.sha256("TestPassword123".encode()).hexdigest()
            cursor.execute(
                "INSERT INTO users (user_id, FirstName, LastName, Email, Phone, Password, UserType, DateCreated, IsActive) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)",
                (test_user_id, "Test", "User", "test.device@example.com", "555-0100", hashed_password, "standard", datetime.datetime.now(), 1)
            )
            connection.commit()
            print("✓ Test user created")
        else:
            print("✓ Test user already exists")
    finally:
        connection.close()
    
    print(f"\nTest User ID: {test_user_id}")
    
    # Stage 1: Register device without token (simulating login before APNs delivers)
    result1 = register_device(
        user_id=test_user_id,
        device_token=None,
        device_type='ios',
        device_name='iPhone 14 Pro',
        app_version='1.0.0',
        os_version='17.4'
    )
    
    print("\nBackend Response:", result1)
    response1 = json.loads(result1)
    
    if response1.get('success'):
        print("✓ Device registered with pending token")
    else:
        print("✗ Failed to register device:", response1.get('error'))
        return False
    
    # Get the pending device ID from database
    cursor, connection = Database.ConnectToDatabase()
    try:
        query = "SELECT device_id FROM user_devices WHERE user_id = %s AND device_token IS NULL LIMIT 1"
        cursor.execute(query, (test_user_id,))
        result = cursor.fetchone()
        if result:
            pending_device_id = result['device_id']
            print(f"✓ Pending device created with ID: {pending_device_id}")
        else:
            print("✗ No pending device found in database")
            connection.close()
            return False
    finally:
        connection.close()
    
    print("\n[STAGE 2] Simulating APNs token delivery")
    print("APNs delivers token...")
    test_token = "abc123def456ghi789jkl012mno345pqr678stu901vwx234yz"
    print(f"Device Token: {test_token}")
    
    # Stage 2: Update with actual token from APNs
    result2 = update_device_token(
        user_id=test_user_id,
        device_type='ios',
        device_token=test_token
    )
    
    print("\nBackend Response:", result2)
    response2 = json.loads(result2)
    
    if response2.get('success'):
        print("✓ Device token updated successfully")
    else:
        print("✗ Failed to update token:", response2.get('error'))
        return False
    
    # Verify in database
    cursor, connection = Database.ConnectToDatabase()
    try:
        query = "SELECT device_id, device_token FROM user_devices WHERE user_id = %s AND device_type = 'ios'"
        cursor.execute(query, (test_user_id,))
        devices = cursor.fetchall()
        
        print(f"\nDevices in database for user:")
        for device in devices:
            token_status = "✓ Token present" if device['device_token'] else "⚠ Pending token"
            print(f"  - Device ID: {device['device_id'][:8]}... - {token_status}")
        
        # Check if our token is there
        token_registered = any(
            d['device_token'] == test_token for d in devices
        )
        
        if token_registered:
            print("\n✓ Token successfully registered in database")
            return True
        else:
            print("\n✗ Token not found in database")
            return False
            
    finally:
        connection.close()

def cleanup_test_data():
    """Clean up test data from database"""
    cursor, connection = Database.ConnectToDatabase()
    try:
        query = "DELETE FROM user_devices WHERE user_id = %s"
        cursor.execute(query, ("USR-test-device-registration-00001",))
        connection.commit()
        print("\n✓ Test data cleaned up")
    finally:
        connection.close()

if __name__ == '__main__':
    try:
        success = test_device_registration()
        
        print("\n" + "="*70)
        if success:
            print("✓ ALL TESTS PASSED - Device registration flow working correctly!")
        else:
            print("✗ TESTS FAILED - Check errors above")
        print("="*70)
        
        # Cleanup
        cleanup_test_data()
        
    except Exception as e:
        print(f"\n✗ Test error: {str(e)}")
        import traceback
        traceback.print_exc()
