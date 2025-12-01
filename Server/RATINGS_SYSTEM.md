# Ratings System Documentation

## Overview

The ratings system allows users to rate and review other users after completing currency exchange transactions. It provides comprehensive analytics and trustworthiness scoring based on user behavior and feedback.

## Database Schema

### user_ratings Table

```sql
CREATE TABLE user_ratings (
    rating_id CHAR(39) PRIMARY KEY,
    user_id CHAR(39) NOT NULL, -- user being rated
    rater_id CHAR(39) NOT NULL, -- user giving the rating
    transaction_id CHAR(39) NULL, -- related transaction
    rating TINYINT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    review TEXT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_rater_id (rater_id),
    INDEX idx_rating (rating),
    INDEX idx_created_at (created_at),
    FOREIGN KEY (user_id) REFERENCES users(UserId) ON DELETE CASCADE,
    FOREIGN KEY (rater_id) REFERENCES users(UserId) ON DELETE CASCADE,
    FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id) ON DELETE SET NULL,
    UNIQUE KEY unique_rating (rater_id, transaction_id)
);
```

The `users` table is updated with an overall `Rating` field that stores the average of all ratings for that user.

## API Endpoints

### 1. Submit a Rating

**Endpoint:** `POST/GET /Ratings/SubmitRating`

**Parameters:**
- `SessionId` (required): Current user's session ID
- `UserId` (required): ID of the user being rated
- `Rating` (required): Rating value from 1-5
- `Review` (optional): Text review
- `TransactionId` (optional): Related transaction ID

**Response:**
```json
{
  "success": true,
  "message": "Rating submitted successfully",
  "ratingId": "uuid"
}
```

**Features:**
- Prevents self-rating
- Allows updating existing ratings (one per transaction)
- Automatically updates user's average rating
- Validates session and users exist

---

### 2. Get User Ratings (Received)

**Endpoint:** `GET /Ratings/GetUserRatings`

**Parameters:**
- `UserId` (required): User to get ratings for
- `Limit` (optional): Number of ratings to return (default: 10)
- `Offset` (optional): Pagination offset (default: 0)

**Response:**
```json
{
  "success": true,
  "ratings": [
    {
      "ratingId": "uuid",
      "rating": 5,
      "review": "Great trader!",
      "createdAt": "2025-11-30T12:00:00",
      "rater": {
        "userId": "USR-xxx",
        "firstName": "John",
        "lastName": "Doe"
      },
      "transaction": {
        "transactionId": "TXN-xxx",
        "amount": 100.00,
        "currency": "USD"
      }
    }
  ],
  "stats": {
    "averageRating": 4.8,
    "totalRatings": 25,
    "distribution": {
      "fiveStar": { "count": 20, "percentage": 80.0 },
      "fourStar": { "count": 4, "percentage": 16.0 },
      "threeStar": { "count": 1, "percentage": 4.0 },
      "twoStar": { "count": 0, "percentage": 0 },
      "oneStar": { "count": 0, "percentage": 0 }
    }
  },
  "pagination": {
    "limit": 10,
    "offset": 0,
    "total": 25
  }
}
```

---

### 3. Get Rating Statistics

**Endpoint:** `GET /Ratings/GetRatingStats`

**Parameters:**
- `UserId` (required): User to get stats for

**Response:**
```json
{
  "success": true,
  "user": {
    "userId": "USR-xxx",
    "firstName": "John",
    "lastName": "Doe",
    "totalExchanges": 42
  },
  "stats": {
    "totalRatings": 25,
    "averageRating": 4.8,
    "lowestRating": 3,
    "highestRating": 5,
    "standardDeviation": 0.45,
    "totalRaters": 24,
    "daysWithRatings": 15,
    "mostRecentRating": "2025-11-30T12:00:00",
    "oldestRating": "2025-09-15T08:30:00",
    "trustworthinessScore": 92.5,
    "distribution": {
      "fiveStar": { "count": 20, "percentage": 80.0 },
      "fourStar": { "count": 4, "percentage": 16.0 },
      "threeStar": { "count": 1, "percentage": 4.0 },
      "twoStar": { "count": 0, "percentage": 0 },
      "oneStar": { "count": 0, "percentage": 0 }
    },
    "recentRatings": [
      {
        "period": "2025-11",
        "count": 8,
        "averageRating": 4.9
      },
      {
        "period": "2025-10",
        "count": 12,
        "averageRating": 4.7
      }
    ]
  }
}
```

---

### 4. Get My Ratings (Given)

**Endpoint:** `GET /Ratings/GetMyRatings`

**Parameters:**
- `SessionId` (required): Current user's session ID
- `Limit` (optional): Number of ratings to return (default: 10)
- `Offset` (optional): Pagination offset (default: 0)

**Response:**
```json
{
  "success": true,
  "ratings": [
    {
      "ratingId": "uuid",
      "rating": 5,
      "review": "Great trader!",
      "createdAt": "2025-11-30T12:00:00",
      "ratedUser": {
        "userId": "USR-xxx",
        "firstName": "Jane",
        "lastName": "Smith",
        "averageRating": 4.6
      },
      "transaction": {
        "transactionId": "TXN-xxx",
        "amount": 100.00,
        "currency": "USD"
      }
    }
  ],
  "pagination": {
    "limit": 10,
    "offset": 0,
    "total": 12
  }
}
```

---

### 5. Get Received Ratings

**Endpoint:** `GET /Ratings/GetReceivedRatings`

**Parameters:**
- `SessionId` (required): Current user's session ID
- `Limit` (optional): Number of ratings to return (default: 10)
- `Offset` (optional): Pagination offset (default: 0)

**Response:**
```json
{
  "success": true,
  "ratings": [
    {
      "ratingId": "uuid",
      "rating": 5,
      "review": "Professional and reliable!",
      "createdAt": "2025-11-30T12:00:00",
      "rater": {
        "userId": "USR-xxx",
        "firstName": "John",
        "lastName": "Doe",
        "averageRating": 4.8
      },
      "transaction": {
        "transactionId": "TXN-xxx",
        "amount": 100.00,
        "currency": "USD"
      }
    }
  ],
  "summary": {
    "averageRating": 4.8,
    "totalRatings": 25,
    "distribution": {
      "fiveStar": 20,
      "fourStar": 4,
      "threeStar": 1,
      "twoStar": 0,
      "oneStar": 0
    }
  },
  "pagination": {
    "limit": 10,
    "offset": 0,
    "total": 25
  }
}
```

---

## Trustworthiness Score

The trustworthiness score (0-100) is calculated based on three factors:

1. **Average Rating (0-50 points)**: Reflects overall rating quality
   - Formula: `(average_rating / 5) * 50`

2. **Volume of Ratings (0-30 points)**: More ratings = more trustworthy
   - Formula: `min(total_ratings / 10, 30)`
   - Maxes out at 30 points with 10+ ratings

3. **Consistency (0-20 points)**: Lower standard deviation = more consistent
   - Formula: `max(0, 20 - (stddev * 10))`
   - Perfect consistency (stddev=0) = 20 points

**Total Score = Rating Component + Volume Component + Consistency Component**

Example:
- Average rating: 4.8 (48 points)
- Total ratings: 25 (30 points max)
- Stddev: 0.45 (15.5 points)
- **Total: 93.5 points**

---

## Usage Examples

### Example 1: Submit a Rating
```bash
curl "http://localhost:9000/Ratings/SubmitRating?SessionId=SES-xxx&UserId=USR-yyy&Rating=5&Review=Great%20trader!"
```

### Example 2: Get User Ratings
```bash
curl "http://localhost:9000/Ratings/GetUserRatings?UserId=USR-xxx&Limit=10&Offset=0"
```

### Example 3: Get Rating Stats
```bash
curl "http://localhost:9000/Ratings/GetRatingStats?UserId=USR-xxx"
```

### Example 4: Get My Ratings
```bash
curl "http://localhost:9000/Ratings/GetMyRatings?SessionId=SES-xxx"
```

---

## Integration Points

### After Completing an Exchange
1. User navigates to the completed transaction
2. Calls `/Ratings/SubmitRating` with the partner's user ID and rating
3. System updates user's average rating automatically

### On User Profile
1. Display user's average rating and total count
2. Show trustworthiness score badge
3. List recent ratings with pagination
4. Show rating distribution chart

### In Search/Browse Results
1. Display user's average rating (star icon)
2. Show trustworthiness score color-coded:
   - Red: 0-50 (Low)
   - Yellow: 50-75 (Medium)
   - Green: 75-100 (High)

---

## Rating Guidelines

Users should rate on these factors:
- **Responsiveness**: Did the user respond quickly?
- **Reliability**: Did they show up for the exchange?
- **Accuracy**: Were the amounts/terms as described?
- **Professionalism**: Were they courteous and professional?
- **Safety**: Did they follow safety guidelines?

---

## Security & Constraints

✓ Users cannot rate themselves
✓ One rating per transaction (updates allowed)
✓ Ratings linked to transactions for accountability
✓ Session validation required
✓ Prevent rating deletion (maintain history)
✓ Auto-update user average on rating changes

---

## Files

- `/Ratings/__init__.py` - Blueprint registration and route definitions
- `/Ratings/SubmitRating.py` - Submit/update rating endpoint
- `/Ratings/GetUserRatings.py` - Get ratings for a user
- `/Ratings/GetRatingStats.py` - Get comprehensive stats for a user
- `/Ratings/GetMyRatings.py` - Get ratings given by current user
- `/Ratings/GetReceivedRatings.py` - Get ratings received by current user

---

## Future Enhancements

- [ ] Weighted ratings based on rater's trustworthiness
- [ ] Report flag for suspicious ratings
- [ ] Rating response feature (seller can respond to rating)
- [ ] Rating moderation/deletion by admins
- [ ] Automated rating reminders after transactions
- [ ] Rating badges/achievements system
- [ ] Rating trends analysis (going up/down)
- [ ] Compare user ratings across date ranges
