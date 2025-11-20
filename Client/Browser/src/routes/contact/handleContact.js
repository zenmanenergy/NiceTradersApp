import { baseURL } from '../../Settings';
import { SuperFetch } from '../../SuperFetch';

/**
 * Get detailed information about a listing and trader for contact page
 */
export async function handleGetContactDetails(listingId, sessionId, userLat = null, userLng = null, callback) {
    console.log('[handleGetContactDetails] Getting contact details for listing:', listingId);
    
    const data = {
        listingId: listingId,
        sessionId: sessionId
    };
    
    // Add user coordinates if available for distance calculation
    if (userLat !== null && userLng !== null) {
        data.userLat = userLat;
        data.userLng = userLng;
    }
    
    const url = `${baseURL}/Contact/GetContactDetails?`;
    
    const response = await SuperFetch(url, data, true);
    console.log('[handleGetContactDetails] Server response:', response);
    if (callback) callback(response);
    return response;
}

/**
 * Check if user already has paid contact access to a specific listing
 */
export async function handleCheckContactAccess(listingId, sessionId, callback) {
    console.log('[handleCheckContactAccess] Checking access for listing:', listingId);
    
    const data = {
        listingId: listingId,
        sessionId: sessionId
    };
    
    const url = `${baseURL}/Contact/CheckContactAccess?`;
    
    const response = await SuperFetch(url, data, true);
    console.log('[handleCheckContactAccess] Server response:', response);
    if (callback) callback(response);
    return response;
}

/**
 * Process payment for contact access to a listing
 */
export async function handlePurchaseContactAccess(listingId, sessionId, paymentMethod = 'default', callback) {
    console.log('[handlePurchaseContactAccess] Processing payment for listing:', listingId);
    
    const data = {
        listingId: listingId,
        sessionId: sessionId,
        paymentMethod: paymentMethod
    };
    
    const url = `${baseURL}/Contact/PurchaseContactAccess?`;
    
    const response = await SuperFetch(url, data, true);
    console.log('[handlePurchaseContactAccess] Server response:', response);
    if (callback) callback(response);
    return response;
}

/**
 * Send interest message to a trader with availability preferences
 */
export async function handleSendInterestMessage(listingId, sessionId, message = '', availability = [], callback) {
    console.log('[handleSendInterestMessage] Sending interest for listing:', listingId);
    
    const data = {
        listingId: listingId,
        sessionId: sessionId,
        message: message,
        availability: JSON.stringify(availability)
    };
    
    const url = `${baseURL}/Contact/SendInterestMessage?`;
    
    const response = await SuperFetch(url, data, true);
    console.log('[handleSendInterestMessage] Server response:', response);
    if (callback) callback(response);
    return response;
}

/**
 * Report a listing for inappropriate content or behavior
 */
export async function handleReportListing(listingId, sessionId, reason, description = '', callback) {
    console.log('[handleReportListing] Reporting listing:', listingId, 'for reason:', reason);
    
    const data = {
        listingId: listingId,
        sessionId: sessionId,
        reason: reason,
        description: description
    };
    
    const url = `${baseURL}/Contact/ReportListing?`;
    
    const response = await SuperFetch(url, data, true);
    console.log('[handleReportListing] Server response:', response);
    if (callback) callback(response);
    return response;
}

/**
 * Get available report reasons for listing reports
 */
export function getReportReasons() {
    return [
        { value: 'spam', label: 'Spam or duplicate listing' },
        { value: 'fraud', label: 'Fraudulent or scam listing' },
        { value: 'inappropriate_content', label: 'Inappropriate content' },
        { value: 'fake_listing', label: 'Fake or misleading listing' },
        { value: 'abusive_behavior', label: 'Abusive behavior from trader' },
        { value: 'misleading_information', label: 'Misleading information' },
        { value: 'other', label: 'Other (please describe)' }
    ];
}