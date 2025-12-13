# Mark Exchange Complete - Testing Guide

## What Was Fixed

The "mark exchange complete" feature now works end-to-end, properly triggering the rating system.

### Changes Made:

1. **Backend**: Registered `/Negotiations/CompleteExchange` endpoint
2. **Backend**: Fixed CompleteExchange.py to use correct database schema
3. **Backend**: CompleteExchange now returns partner_id for rating
4. **iOS**: Captures partner_id and uses it in rating submission
5. **iOS**: Fixed rating submission to use correct API parameter names

## How to Test the Complete Flow

### Prerequisites:
- Two test user accounts
- A listing created by one user
- The other user has proposed a meeting time
- Both parties have agreed on the time
- Both parties have agreed on the meeting location
- Both parties have paid the fees

### Step-by-Step Test:

1. **Create or find an active exchange at the meeting location agreement stage**
   - The iOS app should show the "MARK EXCHANGE COMPLETE" button
   - This button appears when: `timeAcceptedAt != nil && locationAcceptedAt != nil`

2. **Tap "MARK EXCHANGE COMPLETE"**
   - iOS sends request to: `/Negotiations/CompleteExchange?SessionId=X&ListingId=Y`
   - Backend should:
     - ✅ Verify session
     - ✅ Validate both time and location are agreed
     - ✅ Validate both parties have paid
     - ✅ Create exchange_history record
     - ✅ Return partner_id

3. **Rating view should appear**
   - Shows 5-star rating selector
   - Optional feedback text box
   - "SUBMIT RATING" button

4. **Select rating (1-5 stars)**
   - Choose your rating
   - Optionally add feedback text

5. **Tap "SUBMIT RATING"**
   - iOS sends: `/Ratings/SubmitRating?SessionId=X&user_id=PARTNER_ID&Rating=N&Review=TEXT`
   - Backend should:
     - ✅ Create user_ratings record
     - ✅ Update user's overall rating in users table
     - ✅ Return success

6. **Verify completion**
   - Rating view closes (after 1.5 second delay)
   - User returns to home screen
   - Exchange is marked complete in database

## Database Verification

After completing an exchange, you can verify the data was saved:

```sql
-- Check exchange history
SELECT * FROM exchange_history 
WHERE user_id = 'USER_ID' 
ORDER BY ExchangeDate DESC 
LIMIT 1;

-- Check rating was saved
SELECT * FROM user_ratings 
WHERE rater_id = 'RATER_ID' 
AND user_id = 'USER_ID' 
ORDER BY created_at DESC 
LIMIT 1;

-- Check user rating was updated
SELECT user_id, Rating FROM users 
WHERE user_id = 'USER_ID';
```

## Expected Results

✅ Exchange history record created with:
- ExchangeId (UUID)
- user_id (the person who marked it complete)
- ExchangeDate (current timestamp)
- Currency (from listing)
- Amount (from listing)
- PartnerName (opposite party's name)
- Rating (starts at 0, updated when user rates)
- Notes (completion notes)
- TransactionType ('buy' or 'sell')

✅ Rating record created with:
- rating_id (UUID)
- user_id (person being rated - the partner)
- rater_id (person giving the rating - the current user)
- rating (1-5 stars)
- review (optional feedback text)
- created_at (timestamp)

✅ User's overall Rating updated:
- Average of all ratings received
- Displayed on profile with star count

## Error Handling

The system will reject completion if:
- ❌ Session is invalid/expired
- ❌ Listing not found
- ❌ Time has not been agreed (accepted_at is NULL)
- ❌ Location has not been agreed (accepted_at is NULL)
- ❌ Either party hasn't paid (buyer_paid_at or seller_paid_at is NULL)

Rating submission will be rejected if:
- ❌ Session is invalid
- ❌ Partner ID not found
- ❌ Rating is not 1-5
- ❌ User tries to rate themselves
