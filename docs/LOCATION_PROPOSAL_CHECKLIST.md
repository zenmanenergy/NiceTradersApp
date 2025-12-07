# Complete Exchange Workflow - From Listing to Meeting Location

This document outlines the complete end-to-end workflow for a currency exchange on NiceTradersApp. The workflow includes:
1. Creating a listing
2. Searching and finding listings
3. Proposing and negotiating a meeting time
4. Accepting a meeting time
5. Proposing and negotiating a meeting location

The process involves both users' devices (iOS) and the backend server.

---

## Phase 0: Listing Creation

### User A's Device (iOS)
- [x] **Navigate to Create Listing**: User A opens app and goes to create listing
- [x] **Enter Exchange Details**:
  - Currency they have (e.g., USD)
  - Amount they have
  - Currency they want (e.g., JPY)
  - Other details (will round to nearest dollar, etc.)
- [x] **Submit Listing**: User A taps "Create Listing" button
- [x] **Client Network Request**: App sends request to create listing API

### Backend Server
- [x] **Session Validation**: Verify User A's session ID
- [x] **Create Listing**: Insert into `listings` table
  - Fields: `listing_id` (UUID), `user_id` (User A), `currency_from`, `currency_to`
  - Fields: `amount`, `created_at`, `active` (set to true), `notes`, etc.
- [x] **Database Commit**: Persist the listing
- [x] **Return Response**: Return listing ID and confirmation to User A
- [x] **Listing Now Searchable**: Listing appears in search for other users

### User A's Device
- [x] **Success Confirmation**: Listing created and User A returns to dashboard
- [x] **Listing Visible**: Listing shows in User A's "My Active Listings" section
- [x] **Status**: Marked as "Waiting for interest" or similar

---

## Phase 1: User B Searches and Finds Listing

### User B's Device (iOS)
- [x] **Navigate to Search**: User B opens app and goes to search/browse listings
- [x] **Enter Search Criteria**:
  - Currency they have (e.g., JPY)
  - Currency they want (e.g., USD)
  - Amount or range they want
- [x] **View Search Results**: Listings matching criteria are displayed
  - User A's listing appears in results
  - Shows: currency pair, amount, location (if available), user rating
- [x] **View Listing Details**: User B taps on User A's listing to see details
  - Full exchange details
  - User A's profile/rating
  - Contact/propose button

### Backend Server (Search/Browse)
- [ ] **Endpoint Handler**: `/Listings/GetListings` or search endpoint triggered
- [ ] **Query Listings**: Search `listings` table with:
  - `currency_from` = User B wants to give
  - `currency_to` = User B wants to receive
  - `active` = true (only active listings)
  - `user_id` != User B (can't see own listings)
  - Amount matching
- [ ] **Filter Results**: Exclude listings where User B already has access or pending access
- [ ] **Return Results**: JSON with list of matching listings including:
  - `listing_id`, `currency_from`, `currency_to`, `amount`
  - `seller_name`, `seller_rating`, `created_at`
  - `converted_amount` (exchange rate applied)

---

## Phase 2: User B Proposes Initial Meeting Time

### User B's Device (iOS)
- [x] **Navigate to Propose**: User B (buyer) is on listing detail page
- [x] **Select Meeting Time**: Date/time picker presented
  - User B selects desired meeting date and time
- [x] **Submit Proposal**: User B taps "Propose Meeting Time" button
- [ ] **Client Network Request**: App calls `/Negotiations/Propose` endpoint with:
  - `listingId` (User A's listing)
  - `sessionId` (User B's session)
  - `proposedTime` (ISO 8601 datetime format)

### Backend Server (ProposeNegotiation)
- [ ] **Endpoint Handler**: Flask route `/Negotiations/Propose` triggered
- [ ] **Session Validation**: Verify User B's session ID
  - Query `usersessions` with `sessionId`
  - Extract `UserId` (buyer_id = User B)
- [ ] **Listing Lookup**: Verify listing exists and get seller
  - Query `listings` table for `listing_id`
  - Get `user_id` (seller_id = User A)
- [ ] **Verify Not Owner**: Ensure User B is not the listing owner
- [ ] **Create Negotiation Record**: Insert into `exchange_negotiations` table
  - Fields: `negotiation_id` (UUID), `listing_id`, `buyer_id` (User B), `seller_id` (User A)
  - Fields: `status` = 'pending', `created_at` = NOW()
- [ ] **Create History Record**: Insert into `negotiation_history` table
  - Fields: `history_id` (UUID), `negotiation_id`, `listing_id`
  - Fields: `action` = 'time_proposal', `proposed_time` (User B's proposed time)
  - Fields: `proposed_by` = User B, `notes` (optional message)
- [ ] **Database Commit**: Persist both records
- [ ] **Send APN Notification**: 
  - Notify User A that User B proposed a meeting time
  - Message: "User B proposed a meeting on [date and time]"
- [ ] **Return Response**: JSON with:
  - `success: true`
  - `negotiation_id`, `proposal_id`
  - Message: "Meeting time proposal sent"

### User B's Device
- [x] **Success Message**: "Proposal sent! Waiting for acceptance"
- [x] **Return to Dashboard**: Show listing as "Proposal Pending"
  - ✅ **FIXED**: Status mapping added to GetMyNegotiations.py
  - Backend now converts `'time_proposal'` → `'proposed'` status
  - Dashboard will now correctly filter and display proposals

---

## Phase 3: User A Receives and Responds to Time Proposal

### User A's Device (iOS)
- [ ] **APN Notification**: Receive notification that User B proposed a time
  - Message: "User B proposed to meet on Dec 15 at 2:00 PM"
- [x] **Navigate to Negotiation**: Open app or go to Dashboard
- [ ] **View Pending Proposal**: Show listing with pending proposal details
  - Show proposed time
  - Show User B's name and rating
- [ ] **Response Options**: Three buttons available:
  - Accept button
  - Reject button
  - Counter-propose button

### Scenario 3A: User A Accepts the Time Proposal

- [ ] **UI - Accept Button Tapped**: User A taps "Accept" button
- [ ] **Client Network Request**: App calls `/Negotiations/Respond` endpoint with:
  - `negotiationId` (or `proposalId`)
  - `sessionId` (User A's session)
  - `response` = 'accepted'
- [ ] **UI - Loading**: Show loading indicator

### Backend Server (RespondToNegotiation - Accept)
- [ ] **Endpoint Handler**: Flask route `/Negotiations/Respond` triggered
- [ ] **Session Validation**: Verify User A's session
- [ ] **Get Negotiation Details**: Query `exchange_negotiations` table
  - Get: `negotiation_id`, `buyer_id`, `seller_id`, `listing_id`
- [ ] **Permission Check**: Verify User A is the seller in this negotiation
- [ ] **Get Proposal Details**: Query `negotiation_history` for the time proposal
  - Get: `proposed_time`, `history_id`, all proposal details
- [ ] **Update Negotiation Status**: Update `exchange_negotiations`
  - Set `status` = 'time_agreed'
- [ ] **Create Acceptance Record**: Insert into `negotiation_history`
  - Fields: `history_id` (new UUID), `negotiation_id`, `action` = 'accepted_time'
  - Fields: `accepted_time` = copy from proposed_time
  - Fields: `proposed_by` = User A (who is accepting)
- [ ] **Update Listing Status**: Update `listings` table
  - Set `active` = false (listing no longer searchable)
  - Set `negotiation_status` = 'active_exchange' (or similar)
  - This removes it from search results for other users
- [ ] **Database Commit**: Persist all changes
- [ ] **Send Confirmation Notification**:
  - Notify User B that time was accepted
  - Message: "User A accepted your meeting time proposal"
- [ ] **Return Response**: JSON with:
  - `success: true`
  - `message: "Time proposal accepted"`
  - `negotiation_status: 'time_agreed'`

### User A's Device
- [ ] **Success Message**: "Meeting time accepted!"
- [ ] **Listing Status Updates**: Show as "Time Confirmed - Waiting for Location"

### User B's Device (iOS)
- [ ] **APN Notification**: Receive notification that time was accepted
- [ ] **Refresh Dashboard**: When user opens app, listing shows as "Time Agreed"
- [ ] **Next Step**: Ready to propose location

---

### Scenario 3B: User A Rejects the Time Proposal

- [ ] **UI - Reject Button Tapped**: User A taps "Reject" button
- [ ] **Client Network Request**: App calls `/Negotiations/Respond` with:
  - `response` = 'rejected'

### Backend Server (RespondToNegotiation - Reject)
- [ ] **Endpoint Handler**: Flask route `/Negotiations/Respond` triggered
- [ ] **Validation**: Verify User A is the seller
- [ ] **Create Rejection Record**: Insert into `negotiation_history`
  - `action` = 'rejected'
  - DO NOT update listing active status
  - Listing remains active for other buyers
- [ ] **Update Negotiation Status**: Set `status` = 'rejected'
- [ ] **Database Commit**: Persist changes
- [ ] **Send Rejection Notification**: Notify User B
- [ ] **Return Response**: Success message

### User B's Device
- [ ] **Notification**: Time was rejected
- [ ] **Can Propose Again**: User B can propose a different time
- [ ] **Listing Still Available**: The listing remains visible and searchable

---

### Scenario 3C: User A Counter-Proposes Different Time

- [ ] **UI - Counter-Propose Button Tapped**: User A taps "Counter-Propose"
- [ ] **UI - Time Picker**: New time selection interface opens
- [ ] **Select New Time**: User A picks a different date/time
- [ ] **Client Network Request**: App calls `/Negotiations/Propose` with:
  - `negotiationId` (existing negotiation)
  - `sessionId` (User A's session)
  - `proposedTime` (User A's counter time)
- [ ] **UI - Loading**: Show loading state

### Backend Server (ProposeMeeting - Counter-Proposal)
- [ ] **Endpoint Handler**: Flask route `/Negotiations/Propose` triggered
- [ ] **Session Validation**: Verify User A's session
- [ ] **Get Existing Negotiation**: Query `exchange_negotiations`
  - Verify it exists and User A is the seller
- [ ] **Insert Counter-Proposal**: Create new record in `negotiation_history`
  - `action` = 'counter_proposal' (or 'time_counter_proposal')
  - `proposed_time` = User A's new time
  - `proposed_by` = User A
  - Same `negotiation_id`
- [ ] **Negotiation Status**: Update `status` = 'counter_proposed' (optional)
- [ ] **Database Commit**: Persist record
- [ ] **Send Notification**: Notify User B about counter-proposal
- [ ] **Return Response**: Success with proposal ID

### User A's Device
- [ ] **Success Message**: "Counter-proposal sent"
- [ ] **Waiting State**: User A now waits for User B's response

### User B's Device
- [ ] **Notification**: User A counter-proposed a different time
- [ ] **See Counter**: Call `/Negotiations/GetProposals` to fetch updated proposals
- [ ] **Response Options**: Accept, reject, or counter-propose again
- [ ] **Back and Forth**: Both users can keep counter-proposing until agreement

---

## Phase 4: Time Negotiation Resolved - Ready for Location

Once User A and User B have agreed on a meeting time:

### Backend Server State
- [ ] **Negotiation Status**: `exchange_negotiations.status` = 'time_agreed'
- [ ] **Listing Status**: `listings.active` = false (no longer searchable)
- [ ] **Latest Accepted Record**: `negotiation_history` has record with `action` = 'accepted_time'
  - Contains `accepted_time` (the agreed time)

### Both Users' Devices
- [ ] **Dashboard Update**: Both see listing marked as "Time Confirmed"
- [ ] **Next Step**: Location proposal section is now available/enabled
- [ ] **Ready for Phase 5**: Users can now propose location for the confirmed meeting time

---

## Phase 5: User A or User B Proposes a Location

## Phase 5: User A or User B Proposes a Location

### User A (or User B) Device (iOS)
- [ ] **Navigate to Contact View**: Open the active exchange listing that has confirmed time
- [ ] **Location Section Available**: Location proposal section is enabled (time already agreed)
- [ ] **UI - Map Search Available**: User can search for a location on the map
- [ ] **UI - Location Selected**: User selects a location (gets location name, latitude, longitude)
- [ ] **UI - Optional Message**: User can optionally add a message to the proposal
- [ ] **UI - Send Button**: User taps "Propose" or "Send Location" button
- [ ] **Client Network Request**: App constructs URL to `/Meeting/ProposeMeeting` endpoint with:
  - `sessionId` (User A's session)
  - `listingId` (the listing they're exchanging on)
  - `proposedLocation` (location name)
  - `proposedLatitude` (decimal coordinates)
  - `proposedLongitude` (decimal coordinates)
  - `proposedTime` (ISO 8601 format - will be the already-agreed time)
  - `message` (optional message text)
- [ ] **Client - API Call**: iOS makes GET request to `/Meeting/ProposeMeeting`
- [ ] **UI - Loading State**: Show loading indicator to user while waiting for response
- [ ] **UI - Success Feedback**: Display success message when proposal is sent

### Backend Server
- [ ] **Endpoint Handler**: Flask route `/Meeting/ProposeMeeting` is triggered
- [ ] **Session Validation**: Verify User A's session ID is valid
  - Query `usersessions` table with provided `sessionId`
  - Extract `UserId` (User A)
- [ ] **Listing Lookup**: Verify listing exists and get listing owner
  - Query `listings` table for `listing_id`
  - Get `user_id` (listing owner)
- [ ] **Permission Check**: Determine recipient and verify User A can propose
  - If User A is listing owner: Verify buyer exists from `exchange_negotiations` or `contact_access`
  - If User A is buyer: Verify User A is in `exchange_negotiations` for this listing as buyer
  - Set `recipient_id` to the other party
- [ ] **Negotiation Status Check**: Verify time has been agreed (status = 'time_agreed')
  - This prevents location proposals before time is confirmed
- [ ] **Negotiation Lookup**: Check if location proposals already exist
  - Query `negotiation_history` for existing `negotiation_id` where `listing_id` matches
  - If location proposals exist: this is a counter-proposal (set `is_counter_proposal = True`)
  - If no location proposals yet: first location proposal (set `is_counter_proposal = False`)
- [ ] **Time Parsing**: Parse `proposed_time` if provided
  - Should be the already-agreed meeting time
  - Try ISO 8601 format first, then SQL format
  - This time should match the `accepted_time` from earlier negotiation
- [ ] **Action Determination**: Decide the action type based on what was provided
  - If `proposed_location` AND counter-proposal: action = `counter_proposal`
  - If `proposed_location` AND first location proposal: action = `location_proposal`
- [ ] **Database Insert**: Insert history record in `negotiation_history` table
  - Fields: `history_id` (UUID), `negotiation_id`, `listing_id`, `action`
  - Fields: `proposed_time`, `proposed_location`, `proposed_latitude`, `proposed_longitude`
  - Fields: `proposed_by` (User A's ID), `notes` (message), `created_at` (NOW())
  - All accepted_* fields should be NULL at this stage
- [ ] **Database Commit**: Commit the transaction to persist the record
- [ ] **Get Proposer Name**: Query proposer details from `users` table for notification
- [ ] **Send APN Notification**: 
  - Call `notification_service.send_meeting_proposal_notification()`
  - Pass: `recipient_id` (User B), `proposer_name`, `proposed_time`, `listing_id`, `proposal_id`
  - Notification message format: "User A proposed a meeting at [location]"
  - Sent to User B's device
- [ ] **Error Handling**: Catch any exceptions and return JSON error response
- [ ] **Log Output**: Print debug messages for troubleshooting
- [ ] **Return Response**: Return JSON with:
  - `success: true`
  - `proposal_id` (the `history_id` created)
  - `message: "Location proposal sent successfully"`

---

## Phase 6: User B Receives Notification and Views Proposals

### User B's Device (iOS)
- [ ] **APN Notification Received**: Device receives push notification about location proposal
  - Notification content: "User A proposed a meeting at [location]"
- [ ] **User Opens App/View**: User B opens the app or navigates to the contact view for this exchange
- [ ] **Fetch Proposals**: App calls `/Meeting/GetMeetingProposals` endpoint with:
  - `sessionId` (User B's session)
  - `listingId` (same listing)
- [ ] **Display Proposals**: List of proposals displayed in `LocationProposalCard` components
  - Each card shows:
    - Location name
    - Proposed time (already agreed)
    - Message (if any)
    - "From" user name
    - Accept/Reject/Counter-Propose buttons

### Backend Server (GetMeetingProposals)
- [ ] **Endpoint Handler**: Flask route `/Meeting/GetMeetingProposals` is triggered
- [ ] **Session Validation**: Verify User B's session ID is valid
- [ ] **Access Verification**: Verify User B has access to this listing
  - Check if User B is listing owner OR buyer in `exchange_negotiations`
- [ ] **Negotiation Lookup**: Get `negotiation_id` from `negotiation_history` for this listing
- [ ] **Query All Proposals**: Fetch all proposals from `negotiation_history` where:
  - `negotiation_id` matches
  - `action` IN ('location_proposal', 'counter_proposal', 'accepted_time', 'accepted_location')
  - Order by `created_at` DESC
- [ ] **Format Response**: For each proposal, return:
  - `proposal_id` (history_id)
  - `proposed_location`
  - `proposed_latitude`, `proposed_longitude`
  - `proposed_time`
  - `message` (notes field)
  - `status` (pending/accepted/rejected based on action)
  - `proposed_at` (created_at timestamp)
  - `is_from_me` (boolean: compare `proposed_by` to current user)
  - `proposer` object with first and last name
- [ ] **Current Meeting Info**: If there's an accepted location proposal, also return:
  - `current_meeting` object with accepted location, time, and coordinates
- [ ] **Return Response**: JSON with list of location proposals and optional current meeting

---

## Phase 7: User B Responds to Location Proposal

### User B's Device (iOS)
- [ ] **UI - Response Options**: User B sees three buttons on the LocationProposalCard
  - Accept button
  - Reject button
  - Counter-Propose button
- [ ] **User Selects Action**: User B taps one of the action buttons

### Scenario 3A: User B Accepts the Location
- [ ] **UI - Accept Button Tapped**: User B taps "Accept" on the location proposal
- [ ] **Client Network Request**: App calls `/Meeting/RespondToMeeting` with:
  - `sessionId` (User B's session)
  - `proposalId` (the history_id of the proposal)
  - `response` value: `accepted`
- [ ] **UI - Loading State**: Show loading indicator

### Backend Server (RespondToMeeting - Accept)
- [ ] **Endpoint Handler**: Flask route `/Meeting/RespondToMeeting` is triggered
- [ ] **Input Validation**: Verify all required parameters are present and valid
  - `response` must be `accepted` or `rejected`
- [ ] **Session Validation**: Verify User B's session ID is valid
- [ ] **Get Proposal Details**: Query `negotiation_history` for the proposal
  - Get: `history_id`, `negotiation_id`, `proposed_location`, `proposed_time`
  - Get: `proposed_latitude`, `proposed_longitude`, `proposed_by`, `listing_id`
- [ ] **Ownership Check**: Verify User B is NOT the original proposer
  - If User B is the proposer, reject the request
- [ ] **Create Acceptance Record**: Insert new record in `negotiation_history`
  - `history_id` (new UUID for this response)
  - `negotiation_id` (same as original proposal)
  - `action` = `accepted_time` (if proposal had time) OR `accepted_location` (if location-only)
  - Copy values from proposal: `proposed_time`, `proposed_location`, `proposed_latitude`, `proposed_longitude`
  - Set accepted_* fields to copy the proposed_* values
  - `proposed_by` = User B's ID (the person accepting)
- [ ] **Database Commit**: Persist the acceptance record
- [ ] **Send Confirmation Notification**: 
  - Send APN notification to User A that User B accepted the location
  - Message: "User B accepted your location proposal at [location]"
- [ ] **Return Response**: JSON with:
  - `success: true`
  - `message: "Location proposal accepted"`
  - Optional: `current_meeting` details (accepted location and time)

### User A's Device (iOS - Notification)
- [ ] **APN Notification Received**: Notification that User B accepted location
- [ ] **Auto-Refresh**: When user returns to contact view, fetch fresh proposals via `/Meeting/GetMeetingProposals`
- [ ] **UI - Show Accepted State**: Display the accepted location as the current meeting location
- [ ] **UI - Update Done**: Contact view now shows "Current Meeting: [Location Name] at [Time]"

---

### Scenario 3B: User B Rejects the Location
- [ ] **UI - Reject Button Tapped**: User B taps "Reject" on the location proposal
- [ ] **Client Network Request**: App calls `/Meeting/RespondToMeeting` with:
  - `sessionId` (User B's session)
  - `proposalId` (the history_id of the proposal)
  - `response` value: `rejected`
- [ ] **UI - Loading State**: Show loading indicator

### Backend Server (RespondToMeeting - Reject)
- [ ] **Endpoint Handler**: Flask route `/Meeting/RespondToMeeting` is triggered
- [ ] **Session Validation**: Verify User B's session ID is valid
- [ ] **Get Proposal Details**: Query `negotiation_history` for the proposal
- [ ] **Ownership Check**: Verify User B is NOT the original proposer
- [ ] **Create Rejection Record**: Insert new record in `negotiation_history`
  - `history_id` (new UUID for this response)
  - `negotiation_id` (same as original proposal)
  - `action` = `rejected`
  - Copy proposal details but DO NOT set any accepted_* fields (leave NULL)
  - `proposed_by` = User B's ID
- [ ] **Database Commit**: Persist the rejection record
- [ ] **Send Rejection Notification**: 
  - Send APN to User A that User B rejected the location
- [ ] **Return Response**: JSON with `success: true`

### User A's Device (iOS - Notification)
- [ ] **APN Notification Received**: Notification that User B rejected location
- [ ] **UI - Update**: When refreshed, show proposal as "rejected" in the proposal list
- [ ] **UI - Allow Counter-Propose**: User A can now propose a different location

---

### Scenario 3C: User B Counter-Proposes a Different Location
- [ ] **UI - Counter-Propose Button Tapped**: User B taps "Counter-Propose" button
- [ ] **UI - Location Selection**: Interface clears current selection and allows User B to pick a new location
- [ ] **UI - New Location Selected**: User B searches and selects a different location
- [ ] **UI - Optional Message**: User B can add a message explaining the counter-proposal
- [ ] **Client Network Request**: App calls `/Meeting/ProposeMeeting` with:
  - `sessionId` (User B's session - now the proposer)
  - `listingId` (same listing)
  - `proposedLocation` (User B's new location)
  - `proposedLatitude`, `proposedLongitude` (new coordinates)
  - `proposedTime` (User A's original time, if any)
  - `message` (User B's message)

### Backend Server (ProposeMeeting - Counter-Proposal)
- [ ] **Session Validation**: Verify User B's session
- [ ] **Negotiation Lookup**: Find existing `negotiation_id` for this listing
  - Found: `is_counter_proposal = True`
- [ ] **Action Determination**: Set `action = counter_proposal`
- [ ] **Insert History Record**: Create new record with User B as `proposed_by`
  - New coordinates and location
  - Same negotiation_id
- [ ] **Send Notification**: Notify User A about counter-proposal
- [ ] **Return Response**: Success response with new proposal_id

### User A's Device (iOS)
- [ ] **Notification Received**: User A gets notified about counter-proposal
- [ ] **Refresh Proposals**: Call `/Meeting/GetMeetingProposals` when viewing
- [ ] **See Counter-Proposal**: Display User B's new location proposal
- [ ] **Can Accept or Counter Again**: User A now has same options (accept/reject/counter)

---

## Phase 8: Meeting Confirmed and Ready for Exchange

Once a location is finally accepted by both parties, the exchange is fully confirmed:

### Database State
- [ ] **Negotiation Status**: `exchange_negotiations.status` = 'time_agreed' (time confirmed earlier)
- [ ] **Listing Status**: `listings.active` = false (was set when time accepted, still inactive)
- [ ] **Accepted Location Record**: `negotiation_history` has record with:
  - `action` = 'accepted_location'
  - `accepted_location`, `accepted_latitude`, `accepted_longitude` populated
  - `accepted_time` populated (agreed time)
  - Represents the final confirmed meeting details

### Both Users' Devices (iOS)
- [ ] **Confirmed Meeting Display**: Both see confirmed meeting with:
  - Location name
  - Exact coordinates (latitude/longitude)
  - Meeting date and time
  - User details of the other party
- [ ] **Status Badge**: Shows "Meeting Confirmed" or "Ready for Exchange"
- [ ] **View on Map**: Can view the meeting location on the map
- [ ] **Location Tracking Available**: Once the meeting time approaches, location tracking becomes enabled
  - Both users can see each other's live location
  - Can use `/Meeting/Location/Update` to share location
  - Can use `/Meeting/Location/Get` to retrieve other user's location
- [ ] **Exchange Instructions**: Clear directions on when/where/how to meet

---

## Database Tables Involved

### `listings`
- Stores listing information
- Key fields:
  - `listing_id` (UUID) - unique identifier
  - `user_id` - seller/creator
  - `currency_from`, `currency_to` - exchange pair
  - `amount` - amount being offered
  - `active` - set to FALSE once time is agreed
  - `created_at`
  - `negotiation_status` (optional) - tracks exchange status

### `exchange_negotiations`
- Tracks the negotiation between buyer and seller
- Key fields:
  - `negotiation_id` (UUID) - unique identifier for the exchange
  - `listing_id` - which listing
  - `buyer_id` - user who proposed to buy
  - `seller_id` - user who created listing
  - `status` - 'pending', 'time_agreed', 'rejected', 'completed'
  - `created_at`

### `negotiation_history`
- Detailed log of all proposals and responses
- Key fields:
  - `history_id` (UUID) - unique identifier for each action
  - `negotiation_id` (UUID) - groups all actions for one exchange
  - `listing_id` - which listing
  - `action` - 'time_proposal', 'counter_proposal', 'accepted_time', 'location_proposal', 'accepted_location', 'rejected'
  - `proposed_by` - user_id who made this action
  - `proposed_time`, `proposed_location` - what was proposed
  - `proposed_latitude`, `proposed_longitude` - location coordinates
  - `accepted_time`, `accepted_location` - when accepted, copy proposed_* values here
  - `accepted_latitude`, `accepted_longitude` - copy coordinates when accepted
  - `notes` - optional message from proposer
  - `created_at` - timestamp

### `usersessions`
- Session management
- Used to validate user authentication

### `contact_access`
- Tracks who can contact whom (was used for previous listing model)
- May be used for buyer/seller relationship

### `users`
- User information
- Used to get proposer name for notifications

---

## Summary of Actions in Database

### Time Negotiation Phase
1. **User B proposes time**: INSERT into exchange_negotiations (status='pending'), INSERT into negotiation_history (action='time_proposal')
2. **User A accepts time**: INSERT into negotiation_history (action='accepted_time'), UPDATE listings SET active=FALSE
3. **User A rejects time**: INSERT into negotiation_history (action='rejected')
4. **User A counter-proposes time**: INSERT into negotiation_history (action='counter_proposal')

### Location Negotiation Phase
5. **User A proposes location**: INSERT into negotiation_history (action='location_proposal')
6. **User B accepts location**: INSERT into negotiation_history (action='accepted_location', copy proposed_* to accepted_*)
7. **User B rejects location**: INSERT into negotiation_history (action='rejected')
8. **User B counter-proposes location**: INSERT into negotiation_history (action='counter_proposal')

---

## Key Implementation Details

### Listing Searchability
- Listing is searchable until time is agreed
- Once time is accepted: `listings.active` = FALSE
- Listing disappears from search for other users
- Only buyer and seller can access it for location negotiations

### Location-Only vs Location with Time
- Location proposals always include the already-agreed time
- Time never changes during location negotiation
- If time was agreed, location proposals can reference it
- Both time and location are required to confirm a meeting

### Counter-Proposal vs New Proposal
- System tracks whether proposals already exist for location
- If no prior location proposals: first proposal = `location_proposal`
- If prior proposals exist: new proposal = `counter_proposal`
- Both users can counter as many times as needed until agreement

### Notification System
- APN notifications sent via `NotificationService`
- Sent to recipient, not proposer
- Notifications are informational, not blocking
- Resend logic: App fetches latest proposals when user opens view

### Permission Model
- Only buyer and seller can participate in exchange
- Can't accept own proposals
- Both parties must have agreed time before proposing location
- Buyer must have purchased/have access to listing first

---

## Complete Testing Checklist

When testing the complete end-to-end flow, verify:

### Listing Creation Phase
- [ ] **Listing Created**: Seller creates listing successfully
- [ ] **Listing Searchable**: Listing appears in search immediately
- [ ] **Listing Details Correct**: All exchange info displayed accurately

### Time Negotiation Phase
- [ ] **Buyer Proposes Time**: Proposal inserted with action='time_proposal'
- [ ] **Seller Receives Notification**: APN delivered about time proposal
- [ ] **Seller Sees Proposal**: `/Negotiations/GetProposals` returns time proposal
- [ ] **Seller Accepts Time**: Record created with action='accepted_time', accepted_time populated
- [ ] **Listing No Longer Searchable**: listings.active set to FALSE, removed from search
- [ ] **Buyer Notified**: APN sent to buyer that time was accepted
- [ ] **Counter-Proposal Works**: Seller can counter with different time
- [ ] **Back-and-Forth**: Multiple rounds of counter-proposals work correctly

### Location Proposal Phase
- [ ] **Location Proposal Sends**: First location proposal inserted with action='location_proposal'
- [ ] **Receiver Notified**: APN delivered about location proposal
- [ ] **Receiver Sees Proposals**: `/Meeting/GetMeetingProposals` returns location proposals
- [ ] **Location Acceptance Works**: New record with action='accepted_location' created
- [ ] **Coordinates Accurate**: Latitude/longitude match selected location
- [ ] **Time Preserved**: Agreed time is maintained through location proposals
- [ ] **Counter-Location Works**: User can propose different location (action='counter_proposal')
- [ ] **Rejection Works**: Rejected proposals show correct status
- [ ] **Messages Preserved**: Optional messages are stored and returned
- [ ] **Both Users See Same State**: Both users see accepted location when agreement reached

### Error Cases
- [ ] **Invalid Session**: Proper error when session expired
- [ ] **Not Authorized**: Proper error when user not buyer/seller
- [ ] **Listing Not Found**: Proper error when listing doesn't exist
- [ ] **Can't Accept Own Proposal**: Proper error when proposer tries to accept
- [ ] **Time Must Be Agreed First**: Proper error when proposing location without agreed time
- [ ] **Duplicate/Conflicting Data**: System handles edge cases gracefully

