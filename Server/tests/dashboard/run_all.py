#!/usr/bin/env python3
"""
Master script to run all dashboard test scenarios
"""

import os
import sys

def print_menu():
    print("\n" + "="*70)
    print("DASHBOARD STATE TESTING - SELECT A SITUATION")
    print("="*70)
    print("\n1. Situation 1: Buyer Proposes Time (Seller Not Yet Responded)")
    print("2. Situation 2: Seller Accepted Time (No Payments Yet)")
    print("3. Situation 3: Both Paid (Before Location Proposed)")
    print("4. Situation 4: Buyer Proposed Location (Seller Not Yet Responded)")
    print("5. Situation 5: Seller Proposed Location (Buyer Not Yet Responded)")
    print("6. Situation 6: Both Time and Location Accepted (Ready to Meet)")
    print("7. Situation 7: Exchange Completed (Both Rated)")
    print("0. Exit")
    print("\n" + "="*70)

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    scripts = {
        '1': 'situation_1_buyer_proposes_time.py',
        '2': 'situation_2_time_accepted.py',
        '3': 'situation_3_both_paid_no_location.py',
        '4': 'situation_4_buyer_proposes_location.py',
        '5': 'situation_5_seller_proposes_location.py',
        '6': 'situation_6_both_accepted_ready_to_meet.py',
        '7': 'situation_7_completed_and_rated.py',
    }
    
    while True:
        print_menu()
        choice = input("Enter your choice (0-7): ").strip()
        
        if choice == '0':
            print("\n👋 Goodbye!")
            break
        
        if choice in scripts:
            script_path = os.path.join(script_dir, scripts[choice])
            print(f"\n▶️  Running {scripts[choice]}...")
            os.system(f"python3 '{script_path}'")
        else:
            print("\n❌ Invalid choice. Please try again.")
    
if __name__ == '__main__':
    main()
