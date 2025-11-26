import { baseURL } from '../../Settings';
import SuperFetch from '../../SuperFetch';

export async function handleLogin(Email, Password, formValid, callback) {
	console.log("handleLogin", Email, Password, formValid);

	const Data = {
		Email: Email,
		Password: Password
	};

	const url = baseURL + '/Login/Login?';
	let data = await SuperFetch(url, Data, formValid);

	if (data === false) {
		// SuperFetch failed (form invalid or network error)
		callback(false);
		return false;
	}

	// Handle successful login
	if (data && data.SessionId && data.UserType) {
		console.log("Login successful, SessionId:", data.SessionId, "UserType:", data.UserType);
		
		// Set cookies for session
		Cookies.set("SessionId", data.SessionId, { expires: 365 });
		Cookies.set("UserType", data.UserType, { expires: 365 });

		callback(true);
		// Redirect to dashboard after successful login
		window.location.href = "/dashboard";
	} else {
		console.error("Invalid login response, no SessionId or UserType received");
		
		Cookies.remove("SessionId");
		Cookies.remove("UserType");

		callback(false);
	}

	return true;
}
