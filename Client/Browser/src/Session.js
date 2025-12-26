import SuperFetch from './SuperFetch.js';
import { baseURL } from './Settings';

class session {
	session_id = "";
	UserType = "";

	async logout() {
		console.log("Handling logout...");
		Cookies.remove("session_id");
		Cookies.remove("UserType");
		window.location.href = '/login';
	}

	async handleSession() {
		console.log("Handling session...");
		this.get_session_id();

		await this.VerifySession((results) => {
			if (results && results.session_id && results.UserType) {
				console.log("Session verified!", results);
				Cookies.set("session_id", results.session_id, { expires: 365 });
				Cookies.set("UserType", results.UserType, { expires: 365 });
				this.UserType = results.UserType;
			} else {
				this.logout();
			}
		});
	}

	async VerifySession(callback) {
		const VerifySessionData = {
			session_id: this.session_id
		};

		const queryString = Object.keys(VerifySessionData)
			.map(key => key + '=' + encodeURIComponent(VerifySessionData[key]))
			.join('&');

		const url = baseURL + '/Login/Verify?' + queryString;
		console.log(url);
		try {
			const data = await SuperFetch(`${baseURL}/Login/Verify`, VerifySessionData);
			if (data && data.session_id && data.UserType) {
				callback(data);
			} else {
				callback(null);
			}
		} catch (error) {
			console.error("Verify session error:", error);
			callback(null);
		}
	}

	get_session_id() {
		const urlParams = new URLSearchParams(window.location.search);

		if (urlParams.get("session_id")) {
			this.session_id = urlParams.get("session_id");
		} else if (Cookies.get("session_id")) {
			this.session_id = Cookies.get("session_id");
		} else {
			this.session_id = "";
			Cookies.set("previousLocation", location.href);
			location.href = "/login";
		}
		return true;
	}
}

export const Session = new session();
