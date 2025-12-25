#!/usr/bin/env python3
"""
Migration script to rename usersessions table and SessionId column to snake_case.
Renames:
  - usersessions -> user_sessions
  - SessionId -> session_id
"""

import pymysql
import sys

def run_migration():
    try:
        # Connect to database
        db = pymysql.connect(
            host='localhost',
            user='stevenelson',
            password='mwitcitw711',
            database='nicetraders'
        )
        cursor = db.cursor()
        
        print("Starting migration: usersessions -> user_sessions, SessionId -> session_id")
        print("-" * 70)
        
        # Step 1: Rename the table
        print("Step 1: Renaming table 'usersessions' to 'user_sessions'...")
        cursor.execute("ALTER TABLE `usersessions` RENAME TO `user_sessions`")
        print("✓ Table renamed successfully")
        
        # Step 2: Rename the SessionId column
        print("\nStep 2: Renaming column 'SessionId' to 'session_id'...")
        cursor.execute("ALTER TABLE `user_sessions` CHANGE COLUMN `SessionId` `session_id` CHAR(39) NOT NULL")
        print("✓ Column renamed successfully")
        
        # Commit changes
        db.commit()
        print("\n" + "-" * 70)
        print("✓ Migration completed successfully!")
        print("\nNOTE: You must update the following Python files to use the new table and column names:")
        print("  - Server/Login/VerifySession.py")
        print("  - Server/Login/GetLogin.py")
        print("  - Server/Profile/UpdateSettings.py")
        print("  - Server/Profile/GetProfile.py")
        print("  - Any test files that reference usersessions or SessionId")
        
        cursor.close()
        db.close()
        return True
        
    except pymysql.Error as e:
        print(f"\n✗ Database error: {e}")
        return False
    except Exception as e:
        print(f"\n✗ Unexpected error: {e}")
        return False

if __name__ == "__main__":
    success = run_migration()
    sys.exit(0 if success else 1)
