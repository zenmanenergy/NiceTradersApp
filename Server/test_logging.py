#!/usr/bin/env python3
"""
Diagnostic script to test logging setup in cPanel environment.
Upload this to cPanel and run it to diagnose logging issues.
"""

import os
import sys
import logging
from logging.handlers import RotatingFileHandler

print("=" * 60)
print("LOGGING DIAGNOSTIC SCRIPT")
print("=" * 60)

# 1. Check Python version
print(f"\n1. Python Version: {sys.version}")

# 2. Check current working directory
print(f"\n2. Current Working Directory: {os.getcwd()}")

# 3. Check script location
script_path = os.path.abspath(__file__)
script_dir = os.path.dirname(script_path)
print(f"\n3. Script Path: {script_path}")
print(f"   Script Directory: {script_dir}")

# 4. Check if __main__ has __file__
print(f"\n4. __main__ module check:")
if hasattr(sys.modules['__main__'], '__file__'):
    main_file = sys.modules['__main__'].__file__
    print(f"   __main__.__file__: {main_file}")
    print(f"   Absolute: {os.path.abspath(main_file)}")
else:
    print("   WARNING: __main__ has no __file__ attribute")

# 5. Test different log directory approaches
log_dirs = {
    'Current Dir + logs': os.path.join(os.getcwd(), 'logs'),
    'Script Dir + logs': os.path.join(script_dir, 'logs'),
    '/tmp/flask_logs': '/tmp/flask_logs',
}

print(f"\n5. Testing different log directory paths:")
for name, log_dir in log_dirs.items():
    print(f"\n   Testing: {name}")
    print(f"   Path: {log_dir}")
    
    try:
        # Check if exists
        exists = os.path.exists(log_dir)
        print(f"   Exists: {exists}")
        
        # Try to create if not exists
        if not exists:
            os.makedirs(log_dir, mode=0o755)
            print(f"   Created: ✓")
        
        # Check permissions
        is_writable = os.access(log_dir, os.W_OK)
        print(f"   Writable: {is_writable}")
        
        # Try to write a test file
        test_file = os.path.join(log_dir, 'test.txt')
        with open(test_file, 'w') as f:
            f.write('test content\n')
        print(f"   Write test: ✓")
        
        # Try to read it back
        with open(test_file, 'r') as f:
            content = f.read()
        print(f"   Read test: ✓")
        
        # Clean up
        os.remove(test_file)
        print(f"   Cleanup: ✓")
        
        # Try actual logging
        logger = logging.getLogger(f'test_{name}')
        logger.setLevel(logging.INFO)
        
        handler = RotatingFileHandler(
            os.path.join(log_dir, 'test_app.log'),
            maxBytes=1048576,
            backupCount=3
        )
        handler.setFormatter(logging.Formatter('[%(asctime)s] %(message)s'))
        logger.addHandler(handler)
        
        logger.info(f"Test log entry for {name}")
        print(f"   Logging test: ✓")
        
        # Check if file was created and has content
        log_file = os.path.join(log_dir, 'test_app.log')
        if os.path.exists(log_file):
            size = os.path.getsize(log_file)
            print(f"   Log file created: ✓ (size: {size} bytes)")
            with open(log_file, 'r') as f:
                print(f"   Content: {f.read().strip()}")
        else:
            print(f"   ERROR: Log file not created!")
        
        print(f"   ✓ SUCCESS - This location works!")
        
    except Exception as e:
        print(f"   ✗ FAILED: {e}")

# 6. Test stderr/stdout
print(f"\n6. Testing stderr/stdout:")
print("   This is stdout", file=sys.stdout)
print("   This is stderr", file=sys.stderr)

# 7. Environment variables
print(f"\n7. Relevant Environment Variables:")
env_vars = ['HOME', 'USER', 'PATH', 'PYTHONPATH', 'PWD', 'FLASK_APP']
for var in env_vars:
    value = os.environ.get(var, 'Not set')
    print(f"   {var}: {value}")

print("\n" + "=" * 60)
print("DIAGNOSTIC COMPLETE")
print("=" * 60)
print("\nUpload this script to cPanel and run it with:")
print("  python3 test_logging.py")
print("\nOr via web:")
print("  Add to flask_app.py and access /test_logging route")
