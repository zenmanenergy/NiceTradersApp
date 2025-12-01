<script>
	import AdminLayout from './admin/AdminLayout.svelte';
	import SearchView from './admin/SearchView.svelte';
	import UserView from './admin/UserView.svelte';
	import ListingView from './admin/ListingView.svelte';
	import TransactionView from './admin/TransactionView.svelte';
	import ApnMessageView from './admin/ApnMessageView.svelte';
	import LogsView from './admin/LogsView.svelte';
	import PaymentReportsView from './admin/PaymentReportsView.svelte';
	import SuperFetch from '../SuperFetch.js';
	import { viewState, userDetailState, listingDetailState, transactionDetailState } from '../lib/adminStore.js';
	
	async function viewUser(userId, userName = 'User') {
		try {
			// Get user details
			const userResponse = await SuperFetch('/Admin/GetUserById', { userId });
			if (!userResponse.success) throw new Error('Failed to load user');
			
			const currentUser = userResponse.user;
			
			// Get user's listings
			const listingsResponse = await SuperFetch('/Admin/GetUserListings', { userId });
			const userListings = listingsResponse.success ? listingsResponse.listings : [];
			
			// Get user's purchases
			const purchasesResponse = await SuperFetch('/Admin/GetUserPurchases', { userId });
			const userPurchases = purchasesResponse.success ? purchasesResponse.purchases : [];
			
			// Get user's messages
			const messagesResponse = await SuperFetch('/Admin/GetUserMessages', { userId });
			const userMessages = messagesResponse.success ? messagesResponse.messages : [];
			
			// Get user's ratings
			const ratingsResponse = await SuperFetch('/Admin/GetUserRatings', { userId });
			const userRatings = ratingsResponse.success ? ratingsResponse.ratings : [];
			
			// Get user's devices
			const devicesResponse = await SuperFetch('/Admin/GetUserDevices', { userId });
			const userDevices = devicesResponse.success ? devicesResponse.devices : [];
			
			userDetailState.set({ currentUser, userListings, userPurchases, userMessages, userRatings, userDevices });
			
			viewState.update(state => ({
				currentView: 'user',
				breadcrumbs: [...state.breadcrumbs, { type: 'user', id: userId, label: userName }]
			}));
		} catch (err) {
			console.error('Error loading user:', err);
		}
	}
	
	async function viewListing(listingId, listingName = 'Listing') {
		try {
			// Get listing details
			const listingResponse = await SuperFetch('/Admin/GetListingById', { listingId });
			if (!listingResponse.success) throw new Error('Failed to load listing');
			const currentListing = listingResponse.listing;
			
			// Get listing owner
			const ownerResponse = await SuperFetch('/Admin/GetUserById', { userId: currentListing.user_id });
			const listingOwner = ownerResponse.success ? ownerResponse.user : null;
			
			// Get who purchased this listing
			const purchasesResponse = await SuperFetch('/Admin/GetListingPurchases', { listingId });
			const listingPurchases = purchasesResponse.success ? purchasesResponse.purchases : [];
			
			// Get messages for this listing
			const messagesResponse = await SuperFetch('/Admin/GetListingMessages', { listingId });
			const listingMessages = messagesResponse.success ? messagesResponse.messages : [];
			
			listingDetailState.set({ currentListing, listingPurchases, listingMessages, listingOwner });
			
			viewState.update(state => ({
				currentView: 'listing',
				breadcrumbs: [...state.breadcrumbs, { type: 'listing', id: listingId, label: listingName }]
			}));
		} catch (err) {
			console.error('Error loading listing:', err);
		}
	}
	
	async function viewTransaction(transactionId, transactionName = 'Transaction') {
		try {
			// Get transaction details
			const txResponse = await SuperFetch('/Admin/GetTransactionById', { transactionId });
			if (!txResponse.success) throw new Error('Failed to load transaction');
			const currentTransaction = txResponse.transaction;
			
			// Get buyer details
			const buyerResponse = await SuperFetch('/Admin/GetUserById', { userId: currentTransaction.user_id });
			const transactionBuyer = buyerResponse.success ? buyerResponse.user : null;
			
			// Get seller details (listing owner)
			const listingResponse = await SuperFetch('/Admin/GetListingById', { listingId: currentTransaction.listing_id });
			let transactionSeller = null;
			let transactionListing = null;
			if (listingResponse.success) {
				transactionListing = listingResponse.listing;
				const sellerResponse = await SuperFetch('/Admin/GetUserById', { userId: listingResponse.listing.user_id });
				transactionSeller = sellerResponse.success ? sellerResponse.user : null;
			}
			
			transactionDetailState.set({ currentTransaction, transactionBuyer, transactionSeller, transactionListing });
			
			viewState.update(state => ({
				currentView: 'transaction',
				breadcrumbs: [...state.breadcrumbs, { type: 'transaction', id: transactionId, label: transactionName }]
			}));
		} catch (err) {
			console.error('Error loading transaction:', err);
		}
	}
</script>

<AdminLayout>
	{#if $viewState.currentView === 'search'}
		<SearchView {viewUser} {viewListing} {viewTransaction} />
	{:else if $viewState.currentView === 'user'}
		<UserView {viewListing} {viewTransaction} />
	{:else if $viewState.currentView === 'listing'}
		<ListingView {viewUser} {viewTransaction} />
	{:else if $viewState.currentView === 'transaction'}
		<TransactionView {viewUser} {viewListing} />
	{:else if $viewState.currentView === 'apn-message'}
		<ApnMessageView />
	{:else if $viewState.currentView === 'logs'}
		<LogsView />
	{:else if $viewState.currentView === 'payment-reports'}
		<PaymentReportsView />
	{/if}
</AdminLayout>

<style>
	:global(body) {
		margin: 0;
		padding: 0;
		font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
		background: #f5f7fa;
	}
</style>
