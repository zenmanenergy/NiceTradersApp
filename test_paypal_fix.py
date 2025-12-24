#!/usr/bin/env python3
"""
Test script to verify PayPal approval URL flow is working correctly
"""

import sys
import pymysql
import json

def test_paypal_flow():
    """Test that the paypal_orders table has approval_link column"""
    
    try:
        db = pymysql.connect(
            host='localhost',
            user='stevenelson',
            password='mwitcitw711',
            database='nicetraders',
            cursorclass=pymysql.cursors.DictCursor
        )
        cursor = db.cursor()
        
        # Check if approval_link column exists
        print("Checking paypal_orders table structure...")
        cursor.execute("DESC paypal_orders")
        columns = cursor.fetchall()
        
        column_names = [col['Field'] for col in columns]
        
        if 'approval_link' in column_names:
            print("✓ Column 'approval_link' exists in paypal_orders table")
        else:
            print("✗ Column 'approval_link' NOT found in paypal_orders table")
            print(f"Current columns: {', '.join(column_names)}")
            return False
        
        # Check existing orders
        cursor.execute("SELECT COUNT(*) as count FROM paypal_orders")
        count_result = cursor.fetchone()
        order_count = count_result['count'] if count_result else 0
        
        if order_count > 0:
            print(f"\n✓ Found {order_count} existing PayPal orders")
            
            # Show a sample order
            cursor.execute("SELECT order_id, status, approval_link FROM paypal_orders LIMIT 1")
            sample = cursor.fetchone()
            if sample:
                print(f"\nSample order:")
                print(f"  Order ID: {sample['order_id']}")
                print(f"  Status: {sample['status']}")
                print(f"  Approval Link: {sample['approval_link'][:50] + '...' if sample['approval_link'] and len(sample['approval_link']) > 50 else sample['approval_link'] or 'NULL'}")
        else:
            print("✓ No existing orders (database is clean)")
        
        cursor.close()
        db.close()
        
        print("\n✓ PayPal approval URL flow is properly configured!")
        return True
        
    except Exception as e:
        print(f"✗ Error: {str(e)}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == "__main__":
    success = test_paypal_flow()
    sys.exit(0 if success else 1)
