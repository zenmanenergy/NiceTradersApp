import { error } from '@sveltejs/kit';

function getApiUrl() {
	return typeof window !== 'undefined' && (window.location.hostname === '127.0.0.1' || window.location.hostname === 'localhost')
		? 'http://127.0.0.1:9000'
		: 'https://api.nicetraders.net';
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
		
		// Fetch user devices
		const devicesRes = await fetch(`${API_URL}/Admin/GetUserDevices`, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ user_id: userId })
		});
		const devicesData = await devicesRes.json();
		
		return {
			user: userData.user,
			userDevices: devicesData.devices || []
		};
	} catch (err) {
		console.error('Error loading user:', err);
		throw error(500, 'Failed to load user');
	}
}
