// Formatting utilities
export function formatDate(dateStr) {
	if (!dateStr) return '-';
	return new Date(dateStr).toLocaleString();
}

export function formatCurrency(amount, currency = 'USD') {
	if (amount === null || amount === undefined) return '-';
	return `${currency} ${parseFloat(amount).toFixed(2)}`;
}

export function truncateId(id, length = 8) {
	return id?.substring(0, length) + '...' || '-';
}

export function getStatusBadgeClass(status) {
	return status?.toLowerCase() || '';
}
