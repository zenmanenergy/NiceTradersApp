"""
Location Tracking Service for Real-Time User Tracking During Exchanges
Enables both users to see each other's location within 1 mile of meeting point
for 1 hour before the scheduled exchange time (updated to use new normalized tables)
"""

from _Lib import Database
from datetime import datetime, timedelta
import json
import math

class LocationTrackingService:
    # Earth's radius in miles
    EARTH_RADIUS_MILES = 3959
    
    # Tracking radius in miles
    TRACKING_RADIUS_MILES = 1.0
    
    # Time window for tracking (1 hour before exchange)
    TRACKING_WINDOW_HOURS = 1
    
    @staticmethod
    def update_user_location(proposal_id: str, user_id: str, latitude: float, longitude: float) -> dict:
        """
        Update user's current location during an active exchange
        
        Args:
            proposal_id: ID of the location proposal (from listing_meeting_location)
            user_id: ID of the user whose location is being updated
            latitude: Current latitude
            longitude: Current longitude
            
        Returns:
            dict with success status and location data
        """
        cursor, connection = Database.ConnectToDatabase()
        
        try:
            # Get location proposal and meeting details
            proposal_query = """
                SELECT lml.location_negotiation_id, lml.listing_id,
                       lml.meeting_location_lat, lml.meeting_location_lng, lml.accepted_at,
                       lmt.meeting_time
                FROM listing_meeting_location lml
                LEFT JOIN listing_meeting_time lmt ON lml.listing_id = lmt.listing_id
                WHERE lml.location_negotiation_id = %s 
                AND lml.accepted_at IS NOT NULL
            """
            cursor.execute(proposal_query, (proposal_id,))
            proposal = cursor.fetchone()
            
            if not proposal:
                connection.close()
                return {"success": False, "error": "Proposal not found or not accepted"}
            
            # Check if within tracking window (1 hour before exchange)
            meeting_time = proposal['meeting_time']
            if not meeting_time:
                connection.close()
                return {"success": False, "error": "Meeting time not set"}
            
            current_time = datetime.now()
            time_until_exchange = (meeting_time - current_time).total_seconds() / 3600
            
            if time_until_exchange > LocationTrackingService.TRACKING_WINDOW_HOURS or time_until_exchange < 0:
                connection.close()
                return {"success": False, "error": f"Not in tracking window. Exchange in {time_until_exchange:.1f} hours"}
            
            # Check if within 1 mile radius of meeting location
            meeting_lat = proposal['meeting_location_lat']
            meeting_lon = proposal['meeting_location_lng']
            
            if not meeting_lat or not meeting_lon:
                connection.close()
                return {"success": False, "error": "Meeting location not set"}
            
            distance = LocationTrackingService.calculate_distance(
                latitude, longitude, float(meeting_lat), float(meeting_lon)
            )
            
            if distance > LocationTrackingService.TRACKING_RADIUS_MILES:
                connection.close()
                return {
                    "success": False,
                    "error": f"Outside tracking area. {distance:.2f} miles from meeting point",
                    "distance": distance
                }
            
            # Store location update
            timestamp = datetime.utcnow().isoformat()
            insert_query = """
                INSERT INTO user_locations (user_id, proposal_id, latitude, longitude, timestamp, distance_from_meeting)
                VALUES (%s, %s, %s, %s, %s, %s)
                ON DUPLICATE KEY UPDATE
                    latitude = VALUES(latitude),
                    longitude = VALUES(longitude),
                    timestamp = VALUES(timestamp),
                    distance_from_meeting = VALUES(distance_from_meeting)
            """
            cursor.execute(insert_query, (user_id, proposal_id, latitude, longitude, timestamp, distance))
            connection.commit()
            
            connection.close()
            return {
                "success": True,
                "message": "Location updated successfully",
                "distance": distance,
                "tracking_radius": LocationTrackingService.TRACKING_RADIUS_MILES
            }
            
        except Exception as e:
            connection.close()
            return {"success": False, "error": f"Database error: {str(e)}"}
    
    @staticmethod
    def get_other_user_location(proposal_id: str, current_user_id: str) -> dict:
        """
        Get the location of the other user in the exchange
        
        Args:
            proposal_id: ID of the location proposal
            current_user_id: ID of the requesting user
            
        Returns:
            dict with other user's current location or error
        """
        cursor, connection = Database.ConnectToDatabase()
        
        try:
            # Get proposal details to find other user
            proposal_query = """
                SELECT lml.listing_id, lml.buyer_id,
                       lml.meeting_location_lat, lml.meeting_location_lng,
                       l.user_id as seller_id
                FROM listing_meeting_location lml
                LEFT JOIN listings l ON lml.listing_id = l.listing_id
                WHERE lml.location_negotiation_id = %s 
                AND lml.accepted_at IS NOT NULL
            """
            cursor.execute(proposal_query, (proposal_id,))
            proposal = cursor.fetchone()
            
            if not proposal:
                connection.close()
                return {"success": False, "error": "Proposal not found"}
            
            # Determine other user
            buyer_id = proposal['buyer_id']
            seller_id = proposal['seller_id']
            other_user_id = seller_id if current_user_id == buyer_id else buyer_id
            
            # Get other user's latest location
            location_query = """
                SELECT latitude, longitude, timestamp, distance_from_meeting
                FROM user_locations
                WHERE user_id = %s AND proposal_id = %s
                ORDER BY timestamp DESC
                LIMIT 1
            """
            cursor.execute(location_query, (other_user_id, proposal_id))
            location = cursor.fetchone()
            
            if not location:
                connection.close()
                return {"success": False, "error": "Other user location not found"}
            
            # Get other user's name for display
            user_query = """
                SELECT FirstName, LastName FROM users WHERE user_id = %s
            """
            cursor.execute(user_query, (other_user_id,))
            user_info = cursor.fetchone()
            
            connection.close()
            
            return {
                "success": True,
                "other_user_id": other_user_id,
                "name": f"{user_info['FirstName']} {user_info['LastName']}" if user_info else "User",
                "latitude": location['latitude'],
                "longitude": location['longitude'],
                "distance_from_meeting": location['distance_from_meeting'],
                "timestamp": location['timestamp'],
                "meeting_latitude": float(proposal['meeting_location_lat']),
                "meeting_longitude": float(proposal['meeting_location_lng']),
                "tracking_radius": LocationTrackingService.TRACKING_RADIUS_MILES
            }
            
        except Exception as e:
            connection.close()
            return {"success": False, "error": f"Database error: {str(e)}"}
    
    @staticmethod
    def calculate_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """
        Calculate distance between two coordinates in miles using Haversine formula
        
        Args:
            lat1, lon1: First coordinate
            lat2, lon2: Second coordinate
            
        Returns:
            Distance in miles
        """
        # Convert to radians
        lat1_rad = math.radians(lat1)
        lon1_rad = math.radians(lon1)
        lat2_rad = math.radians(lat2)
        lon2_rad = math.radians(lon2)
        
        # Haversine formula
        dlat = lat2_rad - lat1_rad
        dlon = lon2_rad - lon1_rad
        
        a = math.sin(dlat / 2) ** 2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(dlon / 2) ** 2
        c = 2 * math.asin(math.sqrt(a))
        
        distance = LocationTrackingService.EARTH_RADIUS_MILES * c
        return distance
    
    @staticmethod
    def get_tracking_status(proposal_id: str, user_id: str) -> dict:
        """
        Get the current tracking status for a user in a proposal
        
        Args:
            proposal_id: ID of the location proposal
            user_id: ID of the user
            
        Returns:
            dict with tracking status details
        """
        cursor, connection = Database.ConnectToDatabase()
        
        try:
            proposal_query = """
                SELECT lml.listing_id, lmt.meeting_time
                FROM listing_meeting_location lml
                LEFT JOIN listing_meeting_time lmt ON lml.listing_id = lmt.listing_id
                WHERE lml.location_negotiation_id = %s 
                AND lml.accepted_at IS NOT NULL
            """
            cursor.execute(proposal_query, (proposal_id,))
            proposal = cursor.fetchone()
            
            if not proposal:
                connection.close()
                return {"success": False, "error": "Proposal not found"}
            
            if not proposal['meeting_time']:
                connection.close()
                return {"success": False, "error": "Meeting time not set"}
            
            meeting_time = proposal['meeting_time']
            current_time = datetime.now()
            time_until_exchange = (meeting_time - current_time).total_seconds() / 3600
            
            tracking_enabled = 0 < time_until_exchange <= LocationTrackingService.TRACKING_WINDOW_HOURS
            
            connection.close()
            
            return {
                "success": True,
                "proposal_id": proposal_id,
                "tracking_enabled": tracking_enabled,
                "time_until_exchange_hours": time_until_exchange,
                "tracking_window_hours": LocationTrackingService.TRACKING_WINDOW_HOURS,
                "tracking_radius_miles": LocationTrackingService.TRACKING_RADIUS_MILES
            }
            
        except Exception as e:
            connection.close()
            return {"success": False, "error": f"Database error: {str(e)}"}
