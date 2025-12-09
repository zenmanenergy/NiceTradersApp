"""
Migration script to move data from negotiation_history to new tables:
- listing_meeting_time
- listing_meeting_location  
- listing_payments

This script:
1. Archives old negotiation_history to negotiation_history_archive
2. Migrates each negotiation to the new schema
3. Sets buyer_id in listings table
"""

import pymysql
import pymysql.cursors
from datetime import datetime
import uuid

def generate_id():
    """Generate a 39-character ID"""
    return str(uuid.uuid4()).replace('-', '')[:39]

def migrate_negotiations():
    db = pymysql.connect(
        host='localhost',
        user='stevenelson',
        password='mwitcitw711',
        database='nicetraders',
        cursorclass=pymysql.cursors.DictCursor
    )
    cursor = db.cursor()
    
    try:
        # Step 1: Archive old table
        print("Step 1: Archiving negotiation_history...")
        cursor.execute("CREATE TABLE IF NOT EXISTS negotiation_history_archive LIKE negotiation_history")
        cursor.execute("INSERT INTO negotiation_history_archive SELECT * FROM negotiation_history")
        db.commit()
        print("  ✓ Old data archived")
        
        # Step 2: Get all unique negotiations from history
        print("\nStep 2: Analyzing negotiations...")
        cursor.execute("""
            SELECT DISTINCT listing_id, negotiation_id
            FROM negotiation_history
            ORDER BY listing_id
        """)
        negotiations = cursor.fetchall()
        print(f"  Found {len(negotiations)} unique negotiation(s)")
        
        # Step 3: Process each negotiation
        for neg in negotiations:
            listing_id = neg['listing_id']
            print(f"\nProcessing listing: {listing_id}")
            
            # Get all history for this listing
            cursor.execute("""
                SELECT * FROM negotiation_history
                WHERE listing_id = %s
                ORDER BY created_at ASC
            """, (listing_id,))
            history = cursor.fetchall()
            
            if not history:
                continue
            
            # Find buyer_id (first proposer)
            first_record = history[0]
            buyer_id = first_record['proposed_by']
            
            # Get seller_id from listings
            cursor.execute("SELECT user_id FROM listings WHERE listing_id = %s", (listing_id,))
            listing = cursor.fetchone()
            if not listing:
                print(f"  ✗ Listing not found")
                continue
            seller_id = listing['user_id']
            
            print(f"  Buyer: {buyer_id}, Seller: {seller_id}")
            
            # Step 3a: Create time negotiation
            print("  Creating time_negotiation...")
            time_negotiation_id = generate_id()
            
            # Find the last time proposal/counter proposal
            proposed_time = None
            proposed_by = None
            accepted_at = None
            rejected_at = None
            
            for record in history:
                if record['action'] in ['time_proposal', 'counter_proposal']:
                    proposed_time = record['proposed_time']
                    proposed_by = record['proposed_by']
                    accepted_at = None
                    rejected_at = None
                elif record['action'] == 'accepted_time':
                    accepted_at = datetime.now()
                elif record['action'] == 'rejected':
                    rejected_at = datetime.now()
            
            if proposed_time and proposed_by:
                cursor.execute("""
                    INSERT INTO listing_meeting_time 
                    (time_negotiation_id, listing_id, buyer_id, proposed_by, meeting_time, accepted_at, rejected_at)
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                """, (time_negotiation_id, listing_id, buyer_id, proposed_by, proposed_time, accepted_at, rejected_at))
                print(f"    ✓ Time negotiation created (accepted={accepted_at is not None})")
                db.commit()
            
            # Step 3b: Create payment if applicable
            print("  Checking payment status...")
            buyer_paid = any(rec['action'] == 'buyer_paid' for rec in history)
            seller_paid = any(rec['action'] == 'seller_paid' for rec in history)
            
            if buyer_paid or seller_paid:
                payment_id = generate_id()
                buyer_paid_at = datetime.now() if buyer_paid else None
                seller_paid_at = datetime.now() if seller_paid else None
                
                cursor.execute("""
                    INSERT INTO listing_payments
                    (payment_id, listing_id, buyer_id, buyer_paid_at, seller_paid_at)
                    VALUES (%s, %s, %s, %s, %s)
                """, (payment_id, listing_id, buyer_id, buyer_paid_at, seller_paid_at))
                print(f"    ✓ Payment created (buyer_paid={buyer_paid}, seller_paid={seller_paid})")
                db.commit()
            
            # Step 3c: Update listings.buyer_id if negotiation was accepted
            if accepted_at:
                cursor.execute("""
                    UPDATE listings
                    SET buyer_id = %s
                    WHERE listing_id = %s
                """, (buyer_id, listing_id))
                print(f"    ✓ Set listings.buyer_id to {buyer_id}")
                db.commit()
        
        # Step 4: Summary
        print("\n" + "="*50)
        print("MIGRATION SUMMARY")
        print("="*50)
        
        cursor.execute("SELECT COUNT(*) as count FROM listing_meeting_time")
        time_count = cursor.fetchone()['count']
        print(f"✓ Time negotiations created: {time_count}")
        
        cursor.execute("SELECT COUNT(*) as count FROM listing_payments")
        payment_count = cursor.fetchone()['count']
        print(f"✓ Payments created: {payment_count}")
        
        cursor.execute("SELECT COUNT(*) as count FROM listings WHERE buyer_id IS NOT NULL")
        claimed_count = cursor.fetchone()['count']
        print(f"✓ Listings with buyer_id set: {claimed_count}")
        
        print("\n✓ Migration completed successfully!")
        
    except Exception as e:
        db.rollback()
        print(f"\n✗ Migration failed: {e}")
        raise
    finally:
        cursor.close()
        db.close()

if __name__ == '__main__':
    migrate_negotiations()
