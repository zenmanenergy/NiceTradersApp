#!/usr/bin/env python3
"""
Migration script to populate location field with city/state from coordinates
"""

import sys
sys.path.insert(0, '/Users/stevenelson/Documents/GitHub/NiceTradersApp/Server')

import pymysql
from _Lib.Geocoding import GeocodingService

def migrate_locations():
    """Update all listings with coordinate-based locations to city/state"""
    
    db = pymysql.connect(
        host='localhost',
        user='stevenelson',
        password='mwitcitw711',
        database='nicetraders',
        cursorclass=pymysql.cursors.DictCursor
    )
    
    cursor = db.cursor()
    
    try:
        # Get all listings that have coordinates but location looks like "lat, lng"
        query = """
            SELECT listing_id, latitude, longitude, location
            FROM listings
            WHERE latitude IS NOT NULL 
            AND longitude IS NOT NULL
            AND location REGEXP '^[0-9.-]+, [-0-9.]+$'
            ORDER BY created_at DESC
        """
        
        cursor.execute(query)
        listings = cursor.fetchall()
        
        print(f"Found {len(listings)} listings with coordinate-based locations")
        
        updated_count = 0
        failed_count = 0
        
        for listing in listings:
            listing_id = listing['listing_id']
            lat = listing['latitude']
            lng = listing['longitude']
            old_location = listing['location']
            
            try:
                # Reverse geocode
                new_location = GeocodingService.reverse_geocode(lat, lng)
                
                if new_location and new_location != old_location:
                    # Update the listing
                    update_query = """
                        UPDATE listings 
                        SET location = %s, updated_at = NOW()
                        WHERE listing_id = %s
                    """
                    cursor.execute(update_query, (new_location, listing_id))
                    db.commit()
                    
                    print(f"✓ Updated {listing_id}: '{old_location}' -> '{new_location}'")
                    updated_count += 1
                else:
                    print(f"⊘ Skipped {listing_id}: Could not reverse geocode or location unchanged")
                    failed_count += 1
                    
            except Exception as e:
                print(f"✗ Failed to update {listing_id}: {str(e)}")
                failed_count += 1
        
        print(f"\n=== Migration Complete ===")
        print(f"Updated: {updated_count}")
        print(f"Failed: {failed_count}")
        
    finally:
        cursor.close()
        db.close()

if __name__ == '__main__':
    print("Starting location migration...")
    migrate_locations()
