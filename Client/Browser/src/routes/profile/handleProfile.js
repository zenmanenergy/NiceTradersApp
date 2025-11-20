import { baseURL } from '../../Settings.js';
import { SuperFetch } from '../../SuperFetch.js';

export async function handleGetProfile(SessionId, callback) {
	const Data = {
		SessionId: SessionId
	};
	
	const url = baseURL + '/Profile/GetProfile?';
	let data = await SuperFetch(url, Data, true);
	
	callback(data);
}

export async function handleUpdateProfile(SessionId, name, email, phone, location, bio, callback) {
	const Data = {
		SessionId: SessionId,
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

export async function handleGetExchangeHistory(SessionId, callback) {
	const Data = {
		SessionId: SessionId
	};
	
	const url = baseURL + '/Profile/GetExchangeHistory?';
	let data = await SuperFetch(url, Data, true);
	
	callback(data);
}

export async function handleUpdateSettings(SessionId, settingsJson, callback) {
	const Data = {
		SessionId: SessionId,
		settingsJson: settingsJson
	};
	
	const url = baseURL + '/Profile/UpdateSettings?';
	let data = await SuperFetch(url, Data, true);
	
	callback(data);
}

export async function handleDeleteAccount(SessionId, callback) {
	const Data = {
		SessionId: SessionId
	};
	
	const url = baseURL + '/Profile/DeleteAccount?';
	let data = await SuperFetch(url, Data, true);
	
	callback(data);
}