export async function SuperFetch(url, Data, FormValid,debug=false){
	console.log(Data)
	if (!FormValid) {
		console.log("Form not valid");
		// const invalidFields = document.querySelectorAll("input:invalid");
		// if (invalidFields.length > 0) {
		// 	const firstInvalidField = invalidFields[0];
		// 	if (firstInvalidField) {
		// 		firstInvalidField.focus();
		// 	}
		// }
		return true;
	}
	

	const queryString = Object.keys(Data)
		.map(key => key + '=' + (Data[key] === undefined ? '' : encodeURIComponent(Data[key])))
		.join('&');

	url += queryString
	console.log(url)
	if (debug){
		console.log("DEBUG MODE! DID NOT SEND TO SERVER")
		return false
	}
	let results;
	try {
		const response = await fetch(url);
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