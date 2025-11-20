import { baseURL } from '../../Settings';
import { SuperFetch } from '../../SuperFetch';

/**
 * Propose a meeting time and location
 * @param {string} sessionId - User session ID
 * @param {string} listingId - Listing ID
 * @param {string} proposedLocation - Proposed meeting location
 * @param {string} proposedTime - Proposed meeting time (ISO format)
 * @param {string} message - Optional message with the proposal
 * @param {Function} callback - Callback function
 */
export async function handleProposeMeeting(sessionId, listingId, proposedLocation, proposedTime, message = '', callback) {
	console.log('[handleProposeMeeting] Proposing meeting', { listingId, proposedLocation, proposedTime });
	
	const data = {
		sessionId: sessionId,
		listingId: listingId,
		proposedLocation: proposedLocation,
		proposedTime: proposedTime,
		message: message
	};
	
	const url = `${baseURL}/Meeting/ProposeMeeting`;
	
	// For POST requests, we need to use fetch directly since SuperFetch doesn't handle POST properly
	try {
		const response = await fetch(url, {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
			},
			body: JSON.stringify(data)
		});
		const result = await response.json();
		console.log('[handleProposeMeeting] Server response:', result);
		if (callback) callback(result);
		return result;
	} catch (error) {
		console.error('[handleProposeMeeting] Error:', error);
		const errorResponse = { success: false, error: 'Network error: ' + error.message };
		if (callback) callback(errorResponse);
		return errorResponse;
	}
}

/**
 * Respond to a meeting proposal (accept or reject)
 * @param {string} sessionId - User session ID
 * @param {string} proposalId - Proposal ID
 * @param {string} response - 'accepted' or 'rejected'
 * @param {Function} callback - Callback function
 */
export async function handleRespondToMeeting(sessionId, proposalId, response, callback) {
	console.log('[handleRespondToMeeting] Responding to proposal', { proposalId, response });
	
	const data = {
		sessionId: sessionId,
		proposalId: proposalId,
		response: response
	};
	
	const url = `${baseURL}/Meeting/RespondToMeeting`;
	
	// For POST requests, we need to use fetch directly since SuperFetch doesn't handle POST properly
	try {
		const fetchResponse = await fetch(url, {
			method: 'POST',
			headers: {
				'Content-Type': 'application/json',
			},
			body: JSON.stringify(data)
		});
		const serverResponse = await fetchResponse.json();
		console.log('[handleRespondToMeeting] Server response:', serverResponse);
		if (callback) callback(serverResponse);
		return serverResponse;
	} catch (error) {
		console.error('[handleRespondToMeeting] Error:', error);
		const errorResponse = { success: false, error: 'Network error: ' + error.message };
		if (callback) callback(errorResponse);
		return errorResponse;
	}
}

/**
 * Get all meeting proposals for a listing
 * @param {string} sessionId - User session ID
 * @param {string} listingId - Listing ID
 * @param {Function} callback - Callback function
 */
export async function handleGetMeetingProposals(sessionId, listingId, callback) {
	console.log('[handleGetMeetingProposals] Getting meeting proposals for listing:', listingId);
	
	const data = {
		sessionId: sessionId,
		listingId: listingId
	};
	
	const url = `${baseURL}/Meeting/GetMeetingProposals?`;
	
	const response = await SuperFetch(url, data, true);
	console.log('[handleGetMeetingProposals] Server response:', response);
	if (callback) callback(response);
	return response;
}