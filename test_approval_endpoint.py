#!/usr/bin/env python3
"""
Test the PayPal approval URL endpoint
Simulates what happens when calling GetPayPalApprovalURL
"""

import sys
sys.path.insert(0, '/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server')

import pymysql
import pymysql.cursors

def test_get_approval_url(order_id):
    """Test GetPayPalApprovalURL endpoint logic"""
    
    try:
        db = pymysql.connect(
            host='localhost',
            user='stevenelson',
            password='mwitcitw711',
            database='nicetraders',
            cursorclass=pymysql.cursors.DictCursor
        )
        cursor = db.cursor()
        
        # This is exactly what the endpoint does
        print(f"Fetching approval_link for order: {order_id}")
        cursor.execute("""
            SELECT approval_link FROM paypal_orders 
            WHERE order_id = %s
        """, (order_id,))
        result = cursor.fetchone()
        cursor.close()
        db.close()
        
        if not result:
            print(f"✗ Order not found: {order_id}")
            return False
        
        approval_link = result.get('approval_link')
        print(f"✓ Order found!")
        print(f"  approval_link: {approval_link}")
        
        if not approval_link:
            print("⚠ Warning: approval_link is NULL or empty")
            return False
        
        print("✓ GetPayPalApprovalURL endpoint would work correctly")
        return True
        
    except Exception as e:
        print(f"✗ Error: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    # Get first order from database
    db = pymysql.connect(
        host='localhost',
        user='stevenelson',
        password='mwitcitw711',
        database='nicetraders',
        cursorclass=pymysql.cursors.DictCursor
    )
    cursor = db.cursor()
    cursor.execute("SELECT order_id FROM paypal_orders LIMIT 1")
    result = cursor.fetchone()
    cursor.close()
    db.close()
    
    if result:
        test_get_approval_url(result['order_id'])
    else:
        print("No orders found in database")
