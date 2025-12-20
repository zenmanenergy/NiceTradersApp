<script>
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import AdminLayout from '../../admin/AdminLayout.svelte';
	import ListingView from '../../admin/ListingView.svelte';
	import SuperFetch from '../../../SuperFetch.js';
	import { listingDetailState } from '../../../lib/adminStore.js';

	const listingId = $page.params.id;

	onMount(async () => {
		try {
			// Get listing details
			const listingResponse = await SuperFetch('/Admin/GetListingById', { listingId });
			if (!listingResponse.success) throw new Error('Failed to load listing');
			const currentListing = listingResponse.listing;

			// Get listing owner
			const ownerResponse = await SuperFetch('/Admin/GetUserById', { user_id: currentListing.user_id });
			const listingOwner = ownerResponse.success ? ownerResponse.user : null;

			// Get who purchased this listing
			const purchasesResponse = await SuperFetch('/Admin/GetListingPurchases', { listingId });
			const listingPurchases = purchasesResponse.success ? purchasesResponse.purchases : [];

			// Get messages for this listing
			const messagesResponse = await SuperFetch('/Admin/GetListingMessages', { listingId });
			const listingMessages = messagesResponse.success ? messagesResponse.messages : [];

			listingDetailState.set({ currentListing, listingPurchases, listingMessages, listingOwner });
		} catch (err) {
			console.error('Error loading listing:', err);
		}
	});
</script>

<AdminLayout>
	<ListingView />
</AdminLayout>
