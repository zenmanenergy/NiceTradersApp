
import { baseURL } from './Settings.js';

const normalizeRequestUrl = (endpoint, params) => {
	const queryString = Object.keys(params)
		.filter(key => params[key] !== undefined)
		.map(key => `${encodeURIComponent(key)}=${encodeURIComponent(params[key])}`)
		.join('&');

	if (!queryString) return endpoint;
	const separator = endpoint.includes('?') ? '&' : '?';
	return `${endpoint}${separator}${queryString}`;
};

export default async function SuperFetch(url, Data = {}) {
	console.log(Data);

	const requestUrl = normalizeRequestUrl(url, Data);

	const trimmedBase = baseURL.replace(/\/$/, '');
	const trimmedRequest = requestUrl.replace(/^\//, '');
	const finalUrl = `${trimmedBase}/${trimmedRequest}`;

	console.log(finalUrl);
	let results;
	try {
		const response = await fetch(finalUrl);
		results = await response.json();
		if (results.ErrorMessage){
			console.error("uh oh!", results.ErrorMessage+"\n\n"+results.StackTrace)
			throw(results.ErrorMessage+"\n\n"+results.StackTrace)
		}
	} catch (error) {
		if (typeof document !== 'undefined') {
			document.getElementById("ServerURL").innerHTML="<a target='_blank' href='"+url+"'>"+url+"</a>"
			document.getElementById("ServerErrorMessage").innerHTML="<xmp>"+error+"</xmp>"
			document.getElementById("ServerError").style.visibility="";
			document.getElementById("ServerError").style.display="block";
		}
		return false
	}
	return results
}