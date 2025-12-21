import { error } from '@sveltejs/kit';

function getApiUrl() {
	return typeof window !== 'undefined' && (window.location.hostname === '127.0.0.1' || window.location.hostname === 'localhost')
		? 'http://127.0.0.1:9000'
		: 'https://api.nicetraders.net';
}

export async function load({ url }) {
	const searchTerm = url.searchParams.get('q') || '';
	const searchType = url.searchParams.get('type') || 'listings';
	
	console.log(`[Search Page Load] searchTerm="${searchTerm}", searchType="${searchType}"`);
	
	if (!searchTerm) {
		return { searchTerm, searchType, results: [], count: 0 };
	}

	try {
		const API_URL = getApiUrl();
		const endpoint = `${API_URL}/Admin/Search${searchType.charAt(0).toUpperCase() + searchType.slice(1)}?search=${encodeURIComponent(searchTerm)}`;
		console.log(`[Search] Calling endpoint: ${endpoint}`);
		
		const response = await fetch(endpoint, {
			method: 'GET'
		});

		console.log(`[Search] Response status: ${response.status}, content-type: ${response.headers.get('content-type')}`);
		
		if (!response.ok) {
			const text = await response.text();
			console.error(`[Search] API error ${response.status}:`, text.substring(0, 200));
			throw new Error(`API error: ${response.status}`);
		}

		const data = await response.json();
		console.log(`[Search] Got ${(data.data || []).length} results`);
		
		return {
			searchTerm,
			searchType,
			results: data.data || [],
			count: data.data ? data.data.length : 0
		};
	} catch (err) {
		console.error('[Search Error]:', err.message);
		return {
			searchTerm,
			searchType,
			results: [],
			count: 0,
			error: err.message
		};
	}
}
