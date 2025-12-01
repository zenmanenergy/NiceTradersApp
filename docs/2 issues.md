# NICE Traders - Issues that need to be resolved

## Completed ✅

- [x] Logout should go to the LoginView after logging out
- [x] Reduce the height of the purple header by 10px on all views
- [x] Reduce the size of the buttons on the active exchange page
- [x] 10 USD -> 189 MXN on the pending proposals and negotiating details views
- [x] i18n setup in the database for negotiating_detail, counter_proposal, payment_required, payment_success pages
- [x] Allow the proposed date to be anytime after now
- [x] Add text to the proposed date screen that says the location will be determined after the fees are paid
- [x] On the search results page it should say: 10 USD -> 189 MXN
- [x] On the search results page add how long ago it was posted
- [x] After the date/time is proposed it should send the user to the dashboard
- [x] The number of exchanges needs to be incremented
- [x] Change the expiration date from 2 hours to 6 hours
- [x] If the listing is cancelled before payment the buyer should be notified
- [x] If the buyer has paid for the listing, remove the ability to delete the listing
- [x] After the payment for an exchange, the dashboard should not say "action required" - show another message
- [x] Add a transaction complete process on the active exchange
- [x] The propose date/time page calendar arrows don't work - calendar selection broken
- [x] Add a rating on the active exchange view
- [x] After the second person has paid, send the user to the active exchange
- [x] Exchange history view - back button goes to profile, not landing page

## Needs Fix 🔧

(none currently)

## In Progress 🔄

- [x] Active exchange on the dashboard should have 10 USD -> 189 MXN
- [x] The active exchange on the dashboard - remove the lat/lng, replace with the city/state
- [x] On the active exchange add a searchable map to select the meeting location with distance radius
- [x] Edit listing needs to match up with the fields and layout of the create listing

## Backlog 📋
- [ ] Incorporate PayPal into the system
- [ ] Add a way to refund fees on the admin Svelte website
- [x] Add payment reports on the admin website
- [x] Make the ratings system work
- [x] cache the reverse geocoding in the database so it doesn't hit the server and do a reverse geocode over and over on the same coordinates
- [x] with the loginview loads it should automatically place the cursor int he email input box and open the keyboard