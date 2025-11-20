import { baseURL } from '../../Settings';
import { SuperFetch } from '../../SuperFetch';

/**
 * Get user dashboard data
 * @param {string} sessionId - User session ID
 * @param {Function} callback - Callback function
 */
export async function handleGetUserDashboard(sessionId, callback) {
	console.log('[handleGetUserDashboard] Fetching dashboard data');
	
	const data = {
		SessionId: sessionId
	};
	
	const url = `${baseURL}/Dashboard/GetUserDashboard?`;
	
	const response = await SuperFetch(url, data, true);
	console.log('[handleGetUserDashboard] Server response:', response);
	callback(response);
}

/**
 * Get user statistics for dashboard
 * @param {string} sessionId - User session ID
 * @param {Function} callback - Callback function
 */
export async function handleGetUserStatistics(sessionId, callback) {
	console.log('[handleGetUserStatistics] Fetching user statistics');
	
	const data = {
		SessionId: sessionId
	};
	
	const url = `${baseURL}/Dashboard/GetUserStatistics?`;
	
	const response = await SuperFetch(url, data, true);
	console.log('[handleGetUserStatistics] Server response:', response);
	callback(response);
}

/**
 * Get user's active listings for dashboard
 * @param {string} sessionId - User session ID
 * @param {number} limit - Number of listings to fetch
 * @param {Function} callback - Callback function
 */
export async function handleGetMyActiveListings(sessionId, limit = 10, callback) {
	console.log('[handleGetMyActiveListings] Fetching active listings');
	
	const data = {
		SessionId: sessionId,
		limit: limit.toString(),
		status: 'active'
	};
	
	const url = `${baseURL}/Listings/GetListings?`;
	
	const response = await SuperFetch(url, data, true);
	console.log('[handleGetMyActiveListings] Server response:', response);
	callback(response);
}

/**
 * Get dashboard summary (quick stats)
 * @param {string} sessionId - User session ID
 * @param {Function} callback - Callback function
 */
export async function handleGetDashboardSummary(sessionId, callback) {
	console.log('[handleGetDashboardSummary] Fetching dashboard summary');
	
	// This combines both dashboard and statistics data
	handleGetUserDashboard(sessionId, (dashboardResponse) => {
		if (dashboardResponse && dashboardResponse.success) {
			handleGetUserStatistics(sessionId, (statsResponse) => {
				const combinedData = {
					success: true,
					dashboard: dashboardResponse.data,
					statistics: statsResponse && statsResponse.success ? statsResponse.data : null
				};
				callback(combinedData);
			});
		} else {
			callback(dashboardResponse);
		}
	});
}

/**
 * Get listings user has purchased contact access to
 */
export async function handleGetPurchasedContacts(sessionId, callback) {
	console.log('[handleGetPurchasedContacts] Fetching purchased contacts');
	
	const data = {
		sessionId: sessionId
	};
	
	const url = `${baseURL}/Contact/GetPurchasedContacts?`;
	
	const response = await SuperFetch(url, data, true);
	console.log('[handleGetPurchasedContacts] Server response:', response);
	if (callback) callback(response);
	return response;
}

/**
 * Get listings where users have purchased contact access (for listing owners)
 */
export async function handleGetListingPurchases(sessionId, callback) {
	console.log('[handleGetListingPurchases] Fetching listing purchases');
	
	const data = {
		sessionId: sessionId
	};
	
	const url = `${baseURL}/Contact/GetListingPurchases?`;
	
	const response = await SuperFetch(url, data, true);
	console.log('[handleGetListingPurchases] Server response:', response);
	if (callback) callback(response);
	return response;
}

/**
 * Get messages for a specific listing contact
 */
export async function handleGetContactMessages(sessionId, listingId, callback) {
	console.log('[handleGetContactMessages] Fetching messages for listing:', listingId);
	
	const data = {
		sessionId: sessionId,
		listingId: listingId
	};
	
	const url = `${baseURL}/Contact/GetContactMessages?`;
	
	const response = await SuperFetch(url, data, true);
	console.log('[handleGetContactMessages] Server response:', response);
	if (callback) callback(response);
	return response;
}

/**
 * Send a message in a contact conversation
 */
export async function handleSendContactMessage(sessionId, listingId, message, callback) {
	console.log('[handleSendContactMessage] Sending message for listing:', listingId);
	
	const data = {
		sessionId: sessionId,
		listingId: listingId,
		message: message
	};
	
	const url = `${baseURL}/Contact/SendContactMessage?`;
	
	const response = await SuperFetch(url, data, true);
	console.log('[handleSendContactMessage] Server response:', response);
	if (callback) callback(response);
	return response;
}