export const baseURL = (() => {
	if (typeof window !== 'undefined') {
		return (window.location.hostname === '127.0.0.1' || window.location.hostname === 'localhost')
			? 'http://127.0.0.1:9000'
			: 'http://95.216.221.175:9000';
	}
	return 'http://95.216.221.175:9000'; // Default for static builds
})();
