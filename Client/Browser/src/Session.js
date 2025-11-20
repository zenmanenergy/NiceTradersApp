import { baseURL } from './Settings';

class session {
	SessionId = "";
	UserType = "";

	async logout() {
		console.log("Handling logout...");
		Cookies.remove("SessionId");
		Cookies.remove("UserType");
		window.location.href = '/login';
	}

	async handleSession() {
		console.log("Handling session...");
		this.GetSessionId();

		await this.VerifySession((results) => {
			if (results && results.SessionId && results.UserType) {
				console.log("Session verified!", results);
				Cookies.set("SessionId", results.SessionId, { expires: 365 });
				Cookies.set("UserType", results.UserType, { expires: 365 });
				this.UserType = results.UserType;
			} else {
				this.logout();
			}
		});
	}

	async VerifySession(callback) {
		const VerifySessionData = {
			SessionId: this.SessionId
		};

		const queryString = Object.keys(VerifySessionData)
			.map(key => key + '=' + encodeURIComponent(VerifySessionData[key]))
			.join('&');

		const url = baseURL + '/Login/Verify?' + queryString;
		console.log(url);
		try {
			const response = await fetch(url, { method: 'GET' });
			const data = await response.json();
			if (data && data.SessionId && data.UserType) {
				callback(data);
			} else {
				callback(null);
			}
		} catch (error) {
			console.error("Verify session error:", error);
			callback(null);
		}
	}

	GetSessionId() {
		const urlParams = new URLSearchParams(window.location.search);

		if (urlParams.get("SessionId")) {
			this.SessionId = urlParams.get("SessionId");
		} else if (Cookies.get("SessionId")) {
			this.SessionId = Cookies.get("SessionId");
		} else {
			this.SessionId = "";
			Cookies.set("previousLocation", location.href);
			location.href = "/login";
		}
		return true;
	}
}

export const Session = new session();
