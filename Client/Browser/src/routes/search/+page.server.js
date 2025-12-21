import { error } from '@sveltejs/kit';

function getApiUrl() {
	// On server side, always use the production API URL
	console.log('[getApiUrl] Using API URL: https://api.nicetraders.net');
	return 'https://api.nicetraders.net';
}

export async function load({ url, fetch }) {
	const searchTerm = url.searchParams.get('q') || '';
	const searchType = url.searchParams.get('type') || 'listings';
	
	console.log(`[Search Page Load] searchTerm="${searchTerm}", searchType="${searchType}"`);
	
	if (!searchTerm) {
		console.log('[Search] No search term, returning empty results');
		return { searchTerm, searchType, results: [], count: 0 };
	}

	try {
		const API_URL = getApiUrl();
		const endpoint = `${API_URL}/Admin/Search${searchType.charAt(0).toUpperCase() + searchType.slice(1)}?search=${encodeURIComponent(searchTerm)}`;
		console.log(`[Search] Calling endpoint: ${endpoint}`);
		
		const response = await fetch(endpoint, {
			method: 'GET'
		});

		const contentType = response.headers.get('content-type');
		console.log(`[Search] Response status: ${response.status}, content-type: ${contentType}`);
		
		if (!response.ok) {
			const text = await response.text();
			console.error(`[Search] API error ${response.status}, first 500 chars:`, text.substring(0, 500));
			throw new Error(`API error: ${response.status}`);
		}

		const data = await response.json();
		console.log(`[Search] Got ${(data.data || []).length} results`, data);
		
		return {
			searchTerm,
			searchType,
			results: data.data || [],
			count: data.data ? data.data.length : 0
		};
	} catch (err) {
		console.error('[Search Error]:', err.message, err.stack);
		return {
			searchTerm,
			searchType,
			results: [],
			count: 0,
			error: err.message
		};
	}
}
