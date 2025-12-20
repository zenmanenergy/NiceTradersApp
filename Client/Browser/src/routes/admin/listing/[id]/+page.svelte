<script>
	import AdminLayout from '../../AdminLayout.svelte';
	import ListingView from '../../ListingView.svelte';
	import { listingDetailState } from '../../../lib/adminStore.js';

	export let data;

	// Set the store data from the server load
	$: listingDetailState.set({
		currentListing: data.listing,
		listingOwner: data.owner,
		listingPurchases: data.purchases,
		listingMessages: data.messages
	});
</script>

<AdminLayout>
	<ListingView />
</AdminLayout>
