import { error } from '@sveltejs/kit';

export async function load({ params, fetch }) {
	const userId = params.id;
	
	try {
		// Fetch user data
		const userRes = await fetch('http://localhost:9000/Admin/GetUserById', {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ user_id: userId })
		});
		const userData = await userRes.json();
		
		if (!userData.success) {
			throw error(404, 'User not found');
		}
		
		// Fetch user devices
		const devicesRes = await fetch('http://localhost:9000/Admin/GetUserDevices', {
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
