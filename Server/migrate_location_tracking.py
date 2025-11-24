"""
Database migration script to add user_locations table for location tracking
Run this script to set up the location tracking infrastructure
"""

import sqlite3
import os
import sys

def migrate():
    # Get the database path
    db_path = os.path.join(os.path.dirname(__file__), 'nice_traders.db')
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        # Create user_locations table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS user_locations (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id VARCHAR(255) NOT NULL,
                proposal_id VARCHAR(255) NOT NULL,
                latitude DECIMAL(10, 8) NOT NULL,
                longitude DECIMAL(11, 8) NOT NULL,
                distance_from_meeting DECIMAL(10, 4),
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                UNIQUE KEY unique_location (user_id, proposal_id),
                FOREIGN KEY (user_id) REFERENCES users(UserId),
                FOREIGN KEY (proposal_id) REFERENCES meeting_proposals(proposal_id),
                INDEX idx_proposal_timestamp (proposal_id, timestamp),
                INDEX idx_user_timestamp (user_id, timestamp)
            )
        ''')
        
        # Create location_audit_log table for privacy and debugging
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS location_audit_log (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                user_id VARCHAR(255) NOT NULL,
                proposal_id VARCHAR(255) NOT NULL,
                action VARCHAR(50) NOT NULL,
                latitude DECIMAL(10, 8),
                longitude DECIMAL(11, 8),
                distance_from_meeting DECIMAL(10, 4),
                error_message TEXT,
                ip_address VARCHAR(45),
                timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (user_id) REFERENCES users(UserId),
                FOREIGN KEY (proposal_id) REFERENCES meeting_proposals(proposal_id),
                INDEX idx_proposal_action (proposal_id, action),
                INDEX idx_user_action (user_id, action)
            )
        ''')
        
        conn.commit()
        print("✅ Migration successful: user_locations and location_audit_log tables created")
        
    except sqlite3.OperationalError as e:
        if 'already exists' in str(e):
            print("ℹ️  Tables already exist, skipping migration")
        else:
            print(f"❌ Migration error: {e}")
            conn.rollback()
            sys.exit(1)
    finally:
        conn.close()

if __name__ == "__main__":
    migrate()
