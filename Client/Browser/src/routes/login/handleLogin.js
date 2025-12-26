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
	if (data && data.session_id && data.UserType) {
		console.log("Login successful, session_id:", data.session_id, "UserType:", data.UserType);
		
		// Set cookies for session
		Cookies.set("session_id", data.session_id, { expires: 365 });
		Cookies.set("UserType", data.UserType, { expires: 365 });

		callback(true);
		// Redirect to dashboard after successful login
		window.location.href = "/dashboard";
	} else {
		console.error("Invalid login response, no session_id or UserType received");
		
		Cookies.remove("session_id");
		Cookies.remove("UserType");

		callback(false);
	}

	return true;
}
