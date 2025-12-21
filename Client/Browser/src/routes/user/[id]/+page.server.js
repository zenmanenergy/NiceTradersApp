import { error } from '@sveltejs/kit';

function getApiUrl() {
	return 'https://api.nicetraders.net';
}

export async function load({ params, fetch }) {
	const userId = params.id;
	const API_URL = getApiUrl();
	
	try {
		// Fetch user data
		const userRes = await fetch(`${API_URL}/Admin/GetUserById`, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ user_id: userId })
		});
		const userData = await userRes.json();
		
		if (!userData.success) {
			throw error(404, 'User not found');
		}
		
		// Fetch user listings
		const listingsRes = await fetch(`${API_URL}/Admin/GetUserListings`, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ user_id: userId })
		});
		const listingsData = await listingsRes.json();
		
		// Fetch user purchases
		const purchasesRes = await fetch(`${API_URL}/Admin/GetUserPurchases`, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ user_id: userId })
		});
		const purchasesData = await purchasesRes.json();
		
		// Fetch user messages
		const messagesRes = await fetch(`${API_URL}/Admin/GetUserMessages`, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ user_id: userId })
		});
		const messagesData = await messagesRes.json();
		
		// Fetch user devices
		const devicesRes = await fetch(`${API_URL}/Admin/GetUserDevices`, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ user_id: userId })
		});
		const devicesData = await devicesRes.json();
		
		return {
			user: userData.user,
			userListings: listingsData.listings || [],
			userPurchases: purchasesData.purchases || [],
			userMessages: messagesData.messages || [],
			userDevices: devicesData.devices || []
		};
	} catch (err) {
		console.error('Error loading user:', err);
		throw error(500, 'Failed to load user');
	}
}
