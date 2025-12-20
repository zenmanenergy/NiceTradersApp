import { error } from '@sveltejs/kit';

export async function load({ url }) {
	const searchTerm = url.searchParams.get('q') || '';
	const searchType = url.searchParams.get('type') || 'listings';
	
	if (!searchTerm) {
		return { searchTerm, searchType, results: [], count: 0 };
	}

	try {
		const response = await fetch(`http://localhost:9000/Admin/Search${searchType.charAt(0).toUpperCase() + searchType.slice(1)}`, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ search: searchTerm })
		});

		if (!response.ok) {
			throw new Error(`API error: ${response.status}`);
		}

		const data = await response.json();
		return {
			searchTerm,
			searchType,
			results: data.data || [],
			count: data.count || (data.data ? data.data.length : 0)
		};
	} catch (err) {
		console.error('Search error:', err);
		return {
			searchTerm,
			searchType,
			results: [],
			count: 0,
			error: err.message
		};
	}
}
