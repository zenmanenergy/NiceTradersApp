import { baseURL } from '../../Settings';
import { SuperFetch } from '../../SuperFetch';

/**
 * Create a new exchange listing
 * @param {string} sessionId - User session ID
 * @param {Object} listingData - Listing details
 * @param {Function} callback - Callback function
 */
export async function handleCreateListing(sessionId, listingData, callback) {
	console.log('[handleCreateListing] Creating listing:', listingData);
	
	// Build data object
	const data = {
		SessionId: sessionId,
		currency: listingData.currency,
		amount: listingData.amount,
		acceptCurrency: listingData.acceptCurrency,
		location: listingData.location,
		locationRadius: listingData.locationRadius || '5',
		meetingPreference: listingData.meetingPreference || 'public',
		availableUntil: listingData.availableUntil
	};
	
	const url = `${baseURL}/Listings/CreateListing?`;
	
	const response = await SuperFetch(url, data, true);
	console.log('[handleCreateListing] Server response:', response);
	callback(response);
}

/**
 * Get all listings with optional filtering
 * @param {Object} filters - Filter options
 * @param {Function} callback - Callback function
 */
export async function handleGetListings(filters = {}, callback) {
	console.log('[handleGetListings] Fetching listings with filters:', filters);
	
	// Build data object
	const data = {};
	
	if (filters.currency) data.currency = filters.currency;
	if (filters.acceptCurrency) data.acceptCurrency = filters.acceptCurrency;
	if (filters.location) data.location = filters.location;
	if (filters.maxDistance) data.maxDistance = filters.maxDistance;
	if (filters.limit) data.limit = filters.limit;
	if (filters.offset) data.offset = filters.offset;
	
	const url = `${baseURL}/Listings/GetListings?`;
	
	const response = await SuperFetch(url, data, true);
	console.log('[handleGetListings] Server response:', response);
	callback(response);
}

/**
 * Get a specific listing by ID
 * @param {string} listingId - Listing ID
 * @param {Function} callback - Callback function
 */
export async function handleGetListingById(listingId, callback) {
	console.log('[handleGetListingById] Fetching listing:', listingId);
	
	const data = {
		listingId: listingId
	};
	
	const url = `${baseURL}/Listings/GetListingById?`;
	
	const response = await SuperFetch(url, data, true);
	console.log('[handleGetListingById] Server response:', response);
	callback(response);
}

/**
 * Update an existing listing
 * @param {string} sessionId - User session ID
 * @param {string} listingId - Listing ID
 * @param {Object} updateData - Fields to update
 * @param {Function} callback - Callback function
 */
export async function handleUpdateListing(sessionId, listingId, updateData, callback) {
	console.log('[handleUpdateListing] Updating listing:', listingId, updateData);
	
	// Build data object
	const data = {
		SessionId: sessionId,
		listingId: listingId
	};
	
	// Add optional update fields
	if (updateData.currency) data.currency = updateData.currency;
	if (updateData.amount) data.amount = updateData.amount;
	if (updateData.acceptCurrency) data.acceptCurrency = updateData.acceptCurrency;
	if (updateData.location) data.location = updateData.location;
	if (updateData.locationRadius) data.locationRadius = updateData.locationRadius;
	if (updateData.meetingPreference) data.meetingPreference = updateData.meetingPreference;
	if (updateData.availableUntil) data.availableUntil = updateData.availableUntil;
	if (updateData.status) data.status = updateData.status;
	
	const url = `${baseURL}/Listings/UpdateListing?`;
	
	const response = await SuperFetch(url, data, true);
	console.log('[handleUpdateListing] Server response:', response);
	callback(response);
}

/**
 * Delete or deactivate a listing
 * @param {string} sessionId - User session ID
 * @param {string} listingId - Listing ID
 * @param {boolean} permanent - Whether to permanently delete (default: false)
 * @param {Function} callback - Callback function
 */
export async function handleDeleteListing(sessionId, listingId, permanent = false, callback) {
	console.log('[handleDeleteListing] Deleting listing:', listingId, 'permanent:', permanent);
	
	const data = {
		SessionId: sessionId,
		listingId: listingId,
		permanent: permanent ? 'true' : 'false'
	};
	
	const url = `${baseURL}/Listings/DeleteListing?`;
	
	const response = await SuperFetch(url, data, true);
	console.log('[handleDeleteListing] Server response:', response);
	callback(response);
}

/**
 * Get user's own listings
 * @param {string} sessionId - User session ID
 * @param {Function} callback - Callback function
 */
export async function handleGetMyListings(sessionId, callback) {
	console.log('[handleGetMyListings] Fetching user listings');
	
	// This could be a separate endpoint, but for now we'll use the general get with user filtering
	// In a real implementation, you might want a dedicated endpoint like /api/listings/my
	const data = {
		SessionId: sessionId,
		limit: '50' // Get more for user's own listings
	};
	
	const url = `${baseURL}/Listings/GetListings?`;
	
	const response = await SuperFetch(url, data, true);
	console.log('[handleGetMyListings] Server response:', response);
	callback(response);
}