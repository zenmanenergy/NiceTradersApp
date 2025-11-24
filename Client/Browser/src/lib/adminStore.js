import { writable } from 'svelte/store';

// Search state
export const searchState = writable({
	searchType: 'users',
	searchTerm: '',
	searchResults: [],
	loading: false,
	error: null
});

// View state
export const viewState = writable({
	currentView: 'search', // 'search' | 'user' | 'listing' | 'transaction' | 'apn-message'
	breadcrumbs: []
});

// User detail state
export const userDetailState = writable({
	currentUser: null,
	userListings: [],
	userPurchases: [],
	userMessages: [],
	userRatings: []
});

// Listing detail state
export const listingDetailState = writable({
	currentListing: null,
	listingPurchases: [],
	listingMessages: [],
	listingOwner: null
});

// Transaction detail state
export const transactionDetailState = writable({
	currentTransaction: null,
	transactionBuyer: null,
	transactionSeller: null,
	transactionListing: null
});
