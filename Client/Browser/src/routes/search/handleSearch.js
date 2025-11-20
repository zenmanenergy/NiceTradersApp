import { baseURL } from '../../Settings';
import { SuperFetch } from '../../SuperFetch';

/**
 * Search for currency exchange listings with filters
 */
export async function handleSearchListings(filters = {}, callback) {
    console.log('[handleSearchListings] Searching with filters:', filters);
    
    const data = {
        currency: filters.currency || undefined,
        acceptCurrency: filters.acceptCurrency || undefined,
        location: filters.location || undefined,
        maxDistance: filters.maxDistance || undefined,
        minAmount: filters.minAmount || undefined,
        maxAmount: filters.maxAmount || undefined,
        sessionId: filters.sessionId || undefined,
        limit: filters.limit || 20,
        offset: filters.offset || 0
    };
    
    const url = `${baseURL}/Search/SearchListings?`;
    
    const response = await SuperFetch(url, data, true);
    console.log('[handleSearchListings] Server response:', response);
    if (callback) callback(response);
    return response;
}

/**
 * Get available search filter options
 */
export async function handleGetSearchFilters(callback) {
    console.log('[handleGetSearchFilters] Fetching filter options');
    
    const data = {};
    const url = `${baseURL}/Search/GetSearchFilters?`;
    
    const response = await SuperFetch(url, data, true);
    console.log('[handleGetSearchFilters] Server response:', response);
    if (callback) callback(response);
    return response;
}

/**
 * Get popular searches and trending data
 */
export async function handleGetPopularSearches(callback) {
    console.log('[handleGetPopularSearches] Fetching popular searches');
    
    const data = {};
    const url = `${baseURL}/Search/GetPopularSearches?`;
    
    const response = await SuperFetch(url, data, true);
    console.log('[handleGetPopularSearches] Server response:', response);
    if (callback) callback(response);
    return response;
}

/**
 * Perform a quick search with minimal filters
 */
export async function handleQuickSearch(searchTerm, limit = 10, callback) {
    console.log('[handleQuickSearch] Quick search for:', searchTerm);
    
    // Quick search tries to match currency, accept currency, or location
    const filters = {
        limit: limit
    };
    
    // If searchTerm looks like a currency code (3-4 uppercase letters)
    if (/^[A-Z]{3,4}$/.test(searchTerm)) {
        filters.currency = searchTerm;
    } else {
        // Treat as location search
        filters.location = searchTerm;
    }
    
    return await handleSearchListings(filters, callback);
}

/**
 * Search for listings by currency pair
 */
export async function handleCurrencyPairSearch(fromCurrency, toCurrency, options = {}, callback) {
    console.log('[handleCurrencyPairSearch] Searching pair:', fromCurrency, 'to', toCurrency);
    
    const filters = {
        currency: fromCurrency,
        acceptCurrency: toCurrency,
        ...options
    };
    
    return await handleSearchListings(filters, callback);
}

/**
 * Search for listings in a specific location
 */
export async function handleLocationSearch(location, options = {}, callback) {
    console.log('[handleLocationSearch] Searching location:', location);
    
    const filters = {
        location: location,
        ...options
    };
    
    return await handleSearchListings(filters, callback);
}