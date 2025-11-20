#!/usr/bin/env python3
"""
Database Migration: Add Exchange Rate Columns to contact_access table
Run this script to add the missing exchange rate columns
"""

import sys
import os

# Add the server directory to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from _Lib import Database

def migrate_contact_access_table():
    """Add exchange rate columns to contact_access table if they don't exist"""
    try:
        cursor, connection = Database.ConnectToDatabase()
        
        print("=== CONTACT ACCESS TABLE MIGRATION ===")
        
        # Check current table structure
        cursor.execute("DESCRIBE contact_access")
        columns = [row['Field'] for row in cursor.fetchall()]
        print(f"Current columns: {', '.join(columns)}")
        
        # List of columns to add
        columns_to_add = [
            ("exchange_rate", "DECIMAL(15,8) NULL COMMENT 'Rate from listing currency to accept currency'"),
            ("locked_amount", "DECIMAL(15,2) NULL COMMENT 'Calculated amount buyer will pay (in accept_currency)'"),
            ("rate_calculation_date", "DATE NULL COMMENT 'Date rates were retrieved'"),
            ("from_currency", "VARCHAR(10) NULL COMMENT 'Listing currency (what seller has)'"),
            ("to_currency", "VARCHAR(10) NULL COMMENT 'Accept currency (what buyer will pay)'"),
            ("usd_rate_from", "DECIMAL(15,8) NULL COMMENT 'USD rate for listing currency (at time of purchase)'"),
            ("usd_rate_to", "DECIMAL(15,8) NULL COMMENT 'USD rate for accept currency (at time of purchase)'")
        ]
        
        changes_made = False
        
        for column_name, column_definition in columns_to_add:
            if column_name not in columns:
                print(f"Adding column: {column_name}")
                alter_query = f"ALTER TABLE contact_access ADD COLUMN {column_name} {column_definition}"
                cursor.execute(alter_query)
                changes_made = True
            else:
                print(f"Column {column_name} already exists")
        
        if changes_made:
            # Add index for rate_calculation_date if it doesn't exist
            try:
                cursor.execute("CREATE INDEX idx_rate_calculation_date ON contact_access (rate_calculation_date)")
                print("Added index: idx_rate_calculation_date")
            except Exception as e:
                if "Duplicate key name" in str(e):
                    print("Index idx_rate_calculation_date already exists")
                else:
                    print(f"Warning: Could not create index: {str(e)}")
            
            connection.commit()
            print("\n✅ Migration completed successfully!")
        else:
            print("\n✅ No migration needed - all columns already exist!")
        
        # Verify final structure
        cursor.execute("DESCRIBE contact_access")
        final_columns = [row['Field'] for row in cursor.fetchall()]
        print(f"\nFinal columns: {', '.join(final_columns)}")
        
        connection.close()
        
    except Exception as e:
        print(f"❌ Migration failed: {str(e)}")

if __name__ == "__main__":
    migrate_contact_access_table()