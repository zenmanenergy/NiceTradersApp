export const baseURL = (() => {
	if (typeof window !== 'undefined') {
		return (window.location.hostname === '127.0.0.1' || window.location.hostname === 'localhost')
			? 'http://127.0.0.1:9000'
			: 'https://api.nicetraders.net';
	}
	return 'https://api.nicetraders.net'; // Default for static builds
})();

export const Settings = {
	baseURL
};
