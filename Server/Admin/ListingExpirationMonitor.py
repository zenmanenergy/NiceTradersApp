"""
Listing Expiration Monitor - Checks listings expiring soon and sends warnings
"""
from _Lib.Database import ConnectToDatabase
from Admin.NotificationService import notification_service
from datetime import datetime, timedelta

class ListingExpirationMonitor:
    """Service for monitoring and notifying about listing expirations"""
    
    def check_and_notify_expiring_listings(self, days_before_expiration=7):
        """
        Check for listings expiring soon and send notifications
        Should be called once daily by a scheduled task
        
        Args:
            days_before_expiration: How many days before expiration to send warning (default 7)
        
        Returns:
            dict with statistics about notifications sent
        """
        cursor, connection = ConnectToDatabase()
        stats = {
            'notifications_sent': 0,
            'listings_checked': 0,
            'errors': []
        }
        
        try:
            # Get listings expiring soon (within specified days)
            expiration_date = datetime.now() + timedelta(days=days_before_expiration)
            
            cursor.execute("""
                SELECT listing_id, user_id, title, available_until
                FROM listings
                WHERE status = 'active'
                AND available_until <= %s
                AND available_until > NOW()
                AND DATE(last_expiration_warning_sent) < DATE(NOW())
            """, (expiration_date,))
            
            listings = cursor.fetchall()
            stats['listings_checked'] = len(listings)
            
            for listing in listings:
                try:
                    listing_id = listing['listing_id']
                    seller_id = listing['user_id']
                    listing_title = listing['title']
                    available_until = listing['available_until']
                    
                    # Calculate days remaining
                    days_remaining = (available_until - datetime.now()).days
                    
                    if days_remaining > 0:
                        # Send notification
                        notification_service.send_listing_expiration_warning(
                            seller_id=seller_id,
                            listing_id=listing_id,
                            days_remaining=days_remaining,
                            listing_title=listing_title
                        )
                        
                        # Update the warning timestamp
                        cursor.execute("""
                            UPDATE listings
                            SET last_expiration_warning_sent = NOW()
                            WHERE listing_id = %s
                        """, (listing_id,))
                        
                        stats['notifications_sent'] += 1
                        print(f"[ListingExpirationMonitor] Sent expiration warning for listing {listing_id}")
                
                except Exception as listing_error:
                    stats['errors'].append(f"Error processing listing {listing.get('listing_id', 'UNKNOWN')}: {str(listing_error)}")
                    print(f"[ListingExpirationMonitor] Error processing listing: {str(listing_error)}")
            
            connection.commit()
        
        except Exception as e:
            stats['errors'].append(f"Fatal error: {str(e)}")
            print(f"[ListingExpirationMonitor] Fatal error: {str(e)}")
        
        finally:
            cursor.close()
            connection.close()
        
        return stats


# Global instance
listing_expiration_monitor = ListingExpirationMonitor()
