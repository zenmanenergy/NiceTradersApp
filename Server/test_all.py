#!/usr/bin/env python3
"""
Master test script - runs all state tests in sequence
Shows the progression of a complete exchange negotiation
"""

import subprocess
import sys

tests = [
    ("test_1.py", "Buyer proposes a time"),
    ("test_2.py", "Seller accepts the time"),
    ("test_3.py", "Buyer has paid, seller has not"),
    ("test_4.py", "Seller has paid, buyer has not"),
    ("test_5.py", "Both buyer and seller have paid"),
    ("test_6.py", "Seller proposes a location"),
    ("test_7.py", "Buyer accepts location"),
    ("test_8.py", "Buyer proposes a location (counter)"),
    ("test_9.py", "Seller accepts location"),
]

def run_test(script_name):
    """Run a single test script"""
    try:
        result = subprocess.run(
            ["venv/bin/python3", script_name],
            cwd="/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server",
            capture_output=True,
            text=True
        )
        return result.returncode == 0, result.stdout, result.stderr
    except Exception as e:
        return False, "", str(e)

def main():
    print("\n" + "=" * 80)
    print("NICE TRADERS - STATE TESTING SUITE")
    print("=" * 80 + "\n")
    
    passed = 0
    failed = 0
    
    for script, description in tests:
        print(f"\n{'─' * 80}")
        print(f"Running: {description}")
        print(f"Script: {script}")
        print(f"{'─' * 80}")
        
        success, stdout, stderr = run_test(script)
        
        print(stdout)
        
        if success:
            passed += 1
        else:
            failed += 1
            print(f"❌ FAILED: {stderr}")
    
    print(f"\n{'=' * 80}")
    print(f"SUMMARY: {passed} passed, {failed} failed")
    print(f"{'=' * 80}\n")
    
    return 0 if failed == 0 else 1

if __name__ == "__main__":
    sys.exit(main())
