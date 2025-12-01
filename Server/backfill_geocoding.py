#!/usr/bin/env python3
"""
Backfill geocoding for existing listings with coordinates but no geocoded_location
"""

from _Lib import Database
from _Lib.Geocoding import GeocodingService
import sys

def backfill_geocoding():
    """Find all listings with coordinates but no geocoded_location and reverse geocode them"""
    
    try:
        cursor, connection = Database.ConnectToDatabase()
        
        # Find listings with coordinates but no geocoded_location
        query = """
            SELECT listing_id, latitude, longitude, location 
            FROM listings 
            WHERE latitude IS NOT NULL 
            AND longitude IS NOT NULL 
            AND (geocoded_location IS NULL OR geocoded_location = '')
            LIMIT 100
        """
        
        print("[Backfill] Searching for listings without geocoding...")
        cursor.execute(query)
        listings = cursor.fetchall()
        
        if not listings:
            print("[Backfill] No listings found needing geocoding")
            cursor.close()
            connection.close()
            return
        
        print(f"[Backfill] Found {len(listings)} listings to geocode")
        print()
        
        # Process each listing
        updated_count = 0
        for i, listing in enumerate(listings, 1):
            listing_id = listing['listing_id']
            latitude = listing['latitude']
            longitude = listing['longitude']
            current_location = listing['location']
            
            try:
                # Reverse geocode the coordinates
                print(f"[{i}/{len(listings)}] Geocoding {listing_id}: ({latitude}, {longitude})")
                geocoded_location = GeocodingService.reverse_geocode(latitude, longitude)
                
                if geocoded_location and geocoded_location != current_location:
                    # Update the listing with geocoded result
                    update_query = """
                        UPDATE listings 
                        SET geocoded_location = %s, geocoding_updated_at = NOW()
                        WHERE listing_id = %s
                    """
                    cursor.execute(update_query, (geocoded_location, listing_id))
                    connection.commit()
                    updated_count += 1
                    print(f"  ✓ Updated: {geocoded_location}")
                else:
                    print(f"  ⊘ No change: {geocoded_location or current_location}")
                
            except Exception as e:
                print(f"  ✗ Error: {str(e)}")
                continue
        
        cursor.close()
        connection.close()
        
        print()
        print(f"[Backfill] Complete!")
        print(f"  Total processed: {len(listings)}")
        print(f"  Total updated: {updated_count}")
        
        # Print cache statistics
        print()
        print("[Cache Statistics]")
        stats = GeocodingService.get_cache_stats()
        if stats:
            print(f"  Cached locations: {stats['total_cached']}")
            print(f"  Total cache hits: {stats['total_hits']}")
            print(f"  Average hits per location: {stats['avg_hits_per_location']:.2f}")
        
    except Exception as e:
        print(f"[Backfill] Error: {str(e)}")
        sys.exit(1)

if __name__ == '__main__':
    backfill_geocoding()
