<script>
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import SuperFetch from '../../../SuperFetch.js';
	import { formatDate, formatCurrency } from '../../../lib/adminUtils.js';
	import AdminLayout from '$lib/AdminLayout.svelte';
	
	let currentListing = null;
	let listingOwner = null;
	let listingPurchases = [];
	let listingMessages = [];
	let loading = true;
	let error = null;
	
	const listingId = $page.params.id;
	
	async function loadListing() {
		try {
			// Get listing details
			const listingResponse = await SuperFetch('/Admin/GetListingById', { listingId });
			if (!listingResponse.success) throw new Error('Failed to load listing');
			currentListing = listingResponse.listing;
			
			// Get listing owner
			const ownerResponse = await SuperFetch('/Admin/GetUserById', { user_id: currentListing.user_id });
			if (ownerResponse.success) listingOwner = ownerResponse.user;
			
			// Get who purchased this listing
			const purchasesResponse = await SuperFetch('/Admin/GetListingPurchases', { listingId });
			if (purchasesResponse.success) listingPurchases = purchasesResponse.purchases;
			
			// Get messages for this listing
			const messagesResponse = await SuperFetch('/Admin/GetListingMessages', { listingId });
			if (messagesResponse.success) listingMessages = messagesResponse.messages;
		} catch (e) {
			error = e.message;
		} finally {
			loading = false;
		}
	}
	
	onMount(async () => {
		await loadListing();
	});
</script>

<svelte:head>
	<title>Listing - Nice Traders</title>
</svelte:head>

<AdminLayout>
	{#if loading}
		<div class="loading">Loading listing...</div>
	{:else if error}
		<div class="error">{error}</div>
	{:else if currentListing}
		<div class="detail-view">
		
		<div class="detail-header">
			<h2>💱 {currentListing.currency} → {currentListing.accept_currency}</h2>
			<span class="badge {currentListing.status}">{currentListing.status}</span>
		</div>
		
		<div class="detail-grid">
			<div class="info-card">
				<h3>Listing Details</h3>
				<div class="info-row"><strong>Amount:</strong> {formatCurrency(currentListing.amount, currentListing.currency)}</div>
				<div class="info-row"><strong>Location:</strong> {currentListing.location}</div>
				<div class="info-row"><strong>Coordinates:</strong> {currentListing.latitude}, {currentListing.longitude}</div>
				<div class="info-row"><strong>Meeting Preference:</strong> {currentListing.meeting_preference}</div>
				<div class="info-row"><strong>Available Until:</strong> {formatDate(currentListing.available_until)}</div>
				<div class="info-row"><strong>Created:</strong> {formatDate(currentListing.created_at)}</div>
			</div>
			
			{#if listingOwner}
				<div class="info-card">
					<h3>👤 Owner</h3>
					<div class="info-row"><strong>Name:</strong> {listingOwner.FirstName} {listingOwner.LastName}</div>
					<div class="info-row"><strong>Email:</strong> {listingOwner.Email}</div>
					<div class="info-row"><strong>Rating:</strong> {listingOwner.Rating} ⭐</div>
				</div>
			{/if}
		</div>

		<div class="section">
			<h3>💰 Purchases ({listingPurchases.length})</h3>
			{#if listingPurchases.length === 0}
				<p class="empty-state">No purchases yet</p>
			{:else}
				<div class="list-grid">
					{#each listingPurchases as purchase}
						<div class="list-card">
							<div class="list-header">
								<strong>{formatCurrency(purchase.amount, purchase.currency)}</strong>
								<span class="status-badge {purchase.status}">{purchase.status}</span>
							</div>
							<div>Buyer: {purchase.buyer_first_name} {purchase.buyer_last_name}</div>
							<div>Payment: {purchase.payment_method}</div>
							<div class="list-footer">{formatDate(purchase.buyer_paid_at)}</div>
						</div>
					{/each}
				</div>
			{/if}
		</div>

		<div class="section">
			<h3>💬 Messages ({listingMessages.length})</h3>
			{#if listingMessages.length === 0}
				<p class="empty-state">No messages</p>
			{:else}
				<div class="messages-list">
					{#each listingMessages as message}
						<div class="message-card">
							<div class="message-header">
								<span>From: {message.sender_id ? message.sender_id.substring(0, 12) : 'Unknown'}...</span>
								<span>{formatDate(message.sent_at)}</span>
							</div>
							<div class="message-text">{message.message_text || '-'}</div>
						</div>
					{/each}
				</div>
			{/if}
		</div>
	</div>
	{/if}
</AdminLayout>

<style>
	.back-link {
		display: inline-block;
		margin-bottom: 20px;
		color: #667eea;
		text-decoration: none;
		font-weight: 500;
	}
	
	.back-link:hover {
		text-decoration: underline;
	}
	
	.detail-view {
		background: white;
		padding: 30px;
		border-radius: 12px;
		box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
	}

	.detail-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 30px;
		padding-bottom: 20px;
		border-bottom: 2px solid #f0f0f0;
	}

	.detail-header h2 {
		margin: 0;
		font-size: 24px;
		color: #333;
	}

	.badge {
		padding: 8px 16px;
		border-radius: 20px;
		font-size: 12px;
		font-weight: 600;
		text-transform: uppercase;
	}

	.badge.active {
		background: #e8f5e9;
		color: #2e7d32;
	}

	.badge.inactive {
		background: #fff3e0;
		color: #e65100;
	}

	.detail-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
		gap: 20px;
		margin-bottom: 30px;
	}

	.info-card {
		background: #f9f9f9;
		padding: 20px;
		border-radius: 8px;
		border: 1px solid #e0e0e0;
	}

	.info-card h3 {
		margin: 0 0 15px 0;
		color: #333;
		font-size: 16px;
	}

	.info-row {
		display: flex;
		justify-content: space-between;
		margin-bottom: 12px;
		padding-bottom: 12px;
		border-bottom: 1px solid #e0e0e0;
	}

	.info-row:last-child {
		margin-bottom: 0;
		padding-bottom: 0;
		border-bottom: none;
	}

	.section {
		margin-top: 30px;
	}

	.section h3 {
		color: #333;
		font-size: 18px;
		margin-bottom: 15px;
	}

	.empty-state {
		color: #999;
		font-style: italic;
		padding: 20px;
		text-align: center;
	}

	.list-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
		gap: 15px;
	}

	.list-card {
		background: #f9f9f9;
		padding: 15px;
		border-radius: 8px;
		border: 1px solid #e0e0e0;
	}

	.list-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 10px;
	}

	.status-badge {
		padding: 4px 12px;
		border-radius: 12px;
		font-size: 11px;
		font-weight: 600;
		text-transform: uppercase;
	}

	.status-badge.completed {
		background: #e8f5e9;
		color: #2e7d32;
	}

	.status-badge.pending {
		background: #fff3e0;
		color: #e65100;
	}

	.status-badge.buyer_paid {
		background: #e3f2fd;
		color: #1565c0;
	}

	.list-footer {
		font-size: 12px;
		color: #999;
		margin-top: 10px;
	}

	.messages-list {
		display: flex;
		flex-direction: column;
		gap: 10px;
	}

	.message-card {
		background: #f9f9f9;
		padding: 15px;
		border-radius: 8px;
		border-left: 4px solid #667eea;
	}

	.message-header {
		display: flex;
		justify-content: space-between;
		margin-bottom: 10px;
		font-size: 12px;
		color: #999;
	}

	.message-text {
		color: #333;
		line-height: 1.5;
	}

	.loading,
	.error {
		padding: 40px 20px;
		text-align: center;
		font-size: 18px;
		color: #666;
	}

	.error {
		color: #d32f2f;
		background: #ffebee;
		border-radius: 8px;
	}
</style>
