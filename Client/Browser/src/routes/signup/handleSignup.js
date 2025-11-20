import { baseURL } from '../../Settings.js';
import { SuperFetch } from '../../SuperFetch.js';

export async function handleSignup(firstName, lastName, email, phone, password, formValid, callback) {
	console.log("handleSignup", firstName, lastName, email, phone, formValid);

	const Data = {
		firstName: firstName,
		lastName: lastName,
		email: email,
		phone: phone,
		password: password
	};

	const url = baseURL + '/Signup/CreateAccount?';
	let data = await SuperFetch(url, Data, formValid);

	if (data === false) {
		// SuperFetch failed (form invalid or network error)
		callback(false);
		return false;
	}

	// Handle successful signup
	if (data && data.success && data.sessionId && data.userType) {
		console.log("Signup successful, SessionId:", data.sessionId, "UserType:", data.userType);
		
		// Set cookies for session
		Cookies.set("SessionId", data.sessionId, { expires: 365 });
		Cookies.set("UserType", data.userType, { expires: 365 });

		callback(true);
		// Redirect to dashboard after successful signup
		window.location.href = "/dashboard";
	} else {
		console.error("Signup failed:", data.error || "Unknown error");
		callback(false);
	}

	return true;
}

export async function checkEmailExists(email, formValid = true) {
	if (!email) return false;

	// Create data object for SuperFetch
	const checkData = {
		email: email
	};

	const url = `${baseURL}/Signup/CheckEmail?`;
	console.log("Check email URL:", url);

	// Use SuperFetch for GET request
	const result = await SuperFetch(url, checkData, formValid);
	
	if (result === false) {
		// SuperFetch failed
		return false;
	}
	
	return result.exists || false;
}