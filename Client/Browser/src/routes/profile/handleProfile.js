import { baseURL } from '../../Settings.js';
import SuperFetch from '../../SuperFetch.js';

export async function handleGetProfile(session_id, callback) {
	const Data = {
		session_id: session_id
	};
	
	const url = baseURL + '/Profile/GetProfile?';
	let data = await SuperFetch(url, Data, true);
	
	callback(data);
}

export async function handleUpdateProfile(session_id, name, email, phone, location, bio, callback) {
	const Data = {
		session_id: session_id,
		name: name,
		email: email,
		phone: phone,
		location: location,
		bio: bio
	};
	
	const url = baseURL + '/Profile/UpdateProfile?';
	let data = await SuperFetch(url, Data, true);
	
	callback(data);
}

export async function handleGetExchangeHistory(session_id, callback) {
	const Data = {
		session_id: session_id
	};
	
	const url = baseURL + '/Profile/GetExchangeHistory?';
	let data = await SuperFetch(url, Data, true);
	
	callback(data);
}

export async function handleUpdateSettings(session_id, settingsJson, callback) {
	const Data = {
		session_id: session_id,
		settingsJson: settingsJson
	};
	
	const url = baseURL + '/Profile/UpdateSettings?';
	let data = await SuperFetch(url, Data, true);
	
	callback(data);
}

export async function handleDeleteAccount(session_id, callback) {
	const Data = {
		session_id: session_id
	};
	
	const url = baseURL + '/Profile/DeleteAccount?';
	let data = await SuperFetch(url, Data, true);
	
	callback(data);
}