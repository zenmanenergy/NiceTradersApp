<script>
	import SuperFetch from '../../SuperFetch.js';
	import { listingDetailState, viewState } from '../../lib/adminStore.js';
	import { formatDate, formatCurrency } from '../../lib/adminUtils.js';
	
	function viewUser(userId, userName) {
		viewState.update(state => ({
			...state,
			breadcrumbs: [...state.breadcrumbs, { type: 'user', id: userId, label: userName }]
		}));
	}
	
	function viewTransaction(transactionId, transactionName) {
		viewState.update(state => ({
			...state,
			breadcrumbs: [...state.breadcrumbs, { type: 'transaction', id: transactionId, label: transactionName }]
		}));
	}
</script>

{#if $listingDetailState.currentListing}
	<div class="detail-view">
		<div class="detail-header">
			<h2>💱 {$listingDetailState.currentListing.currency} → {$listingDetailState.currentListing.accept_currency}</h2>
			<span class="badge {$listingDetailState.currentListing.status}">{$listingDetailState.currentListing.status}</span>
		</div>
		
		<div class="detail-grid">
			<div class="info-card">
				<h3>Listing Details</h3>
				<div class="info-row"><strong>Amount:</strong> {formatCurrency($listingDetailState.currentListing.amount, $listingDetailState.currentListing.currency)}</div>
				<div class="info-row"><strong>Location:</strong> {$listingDetailState.currentListing.location}</div>
				<div class="info-row"><strong>Coordinates:</strong> {$listingDetailState.currentListing.latitude}, {$listingDetailState.currentListing.longitude}</div>
				<div class="info-row"><strong>Meeting Preference:</strong> {$listingDetailState.currentListing.meeting_preference}</div>
				<div class="info-row"><strong>Available Until:</strong> {formatDate($listingDetailState.currentListing.available_until)}</div>
				<div class="info-row"><strong>Created:</strong> {formatDate($listingDetailState.currentListing.created_at)}</div>
			</div>
			
			{#if $listingDetailState.listingOwner}
				<div class="info-card clickable" on:click={() => viewUser($listingDetailState.listingOwner.UserId, `${$listingDetailState.listingOwner.FirstName} ${$listingDetailState.listingOwner.LastName}`)}>
					<h3>👤 Owner</h3>
					<div class="info-row"><strong>Name:</strong> {$listingDetailState.listingOwner.FirstName} {$listingDetailState.listingOwner.LastName}</div>
					<div class="info-row"><strong>Email:</strong> {$listingDetailState.listingOwner.Email}</div>
					<div class="info-row"><strong>Rating:</strong> {$listingDetailState.listingOwner.Rating} ⭐</div>
					<div class="click-hint">Click to view user →</div>
				</div>
			{/if}
		</div>

		<div class="section">
			<h3>💰 Purchases ({$listingDetailState.listingPurchases.length})</h3>
			{#if $listingDetailState.listingPurchases.length === 0}
				<p class="empty-state">No purchases yet</p>
			{:else}
				<div class="list-grid">
					{#each $listingDetailState.listingPurchases as purchase}
						<div class="list-card" on:click={() => viewTransaction(purchase.access_id, `Purchase ${purchase.access_id.substring(0, 8)}`)}>
							<div class="list-header">
								<strong>{formatCurrency(purchase.amount_paid, purchase.currency)}</strong>
								<span class="status-badge {purchase.status}">{purchase.status}</span>
							</div>
							<div>Buyer ID: {purchase.user_id.substring(0, 12)}...</div>
							<div>Payment: {purchase.payment_method}</div>
							<div class="list-footer">{formatDate(purchase.purchased_at)}</div>
						</div>
					{/each}
				</div>
			{/if}
		</div>

		<div class="section">
			<h3>💬 Messages ({$listingDetailState.listingMessages.length})</h3>
			{#if $listingDetailState.listingMessages.length === 0}
				<p class="empty-state">No messages</p>
			{:else}
				<div class="messages-list">
					{#each $listingDetailState.listingMessages as message}
						<div class="message-card">
							<div class="message-header">
								<span>From: {message.sender_id.substring(0, 12)}...</span>
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

<style>
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
		color: #333;
	}

	.badge {
		padding: 8px 16px;
		border-radius: 20px;
		font-size: 0.85rem;
		font-weight: 600;
		text-transform: uppercase;
	}

	.badge.active {
		background: #4caf50;
		color: white;
	}

	.badge.inactive {
		background: #f44336;
		color: white;
	}

	.detail-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
		gap: 20px;
		margin-bottom: 30px;
	}

	.info-card {
		background: #f8f9fa;
		padding: 20px;
		border-radius: 10px;
		border: 2px solid transparent;
		transition: all 0.2s;
	}

	.info-card.clickable {
		cursor: pointer;
	}

	.info-card.clickable:hover {
		border-color: #667eea;
		transform: translateY(-2px);
		box-shadow: 0 4px 12px rgba(102, 126, 234, 0.15);
	}

	.info-card h3 {
		margin: 0 0 15px 0;
		color: #333;
		font-size: 1.1rem;
	}

	.info-row {
		padding: 8px 0;
		border-bottom: 1px solid #e0e0e0;
		font-size: 0.95rem;
	}

	.info-row:last-child {
		border-bottom: none;
	}

	.info-row strong {
		color: #666;
		display: inline-block;
		min-width: 150px;
	}

	.click-hint {
		margin-top: 15px;
		color: #667eea;
		font-weight: 500;
		font-size: 0.9rem;
	}

	.section {
		margin-top: 30px;
		padding-top: 30px;
		border-top: 2px solid #f0f0f0;
	}

	.section h3 {
		margin: 0 0 20px 0;
		color: #333;
	}

	.list-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
		gap: 15px;
	}

	.list-card {
		padding: 16px;
		background: #f8f9fa;
		border-radius: 8px;
		cursor: pointer;
		transition: all 0.2s;
		border: 2px solid transparent;
	}

	.list-card:hover {
		border-color: #667eea;
		transform: translateY(-2px);
		box-shadow: 0 4px 12px rgba(102, 126, 234, 0.15);
	}

	.list-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 10px;
	}

	.list-footer {
		margin-top: 10px;
		font-size: 0.85rem;
		color: #999;
	}

	.status-badge {
		padding: 4px 10px;
		border-radius: 12px;
		font-size: 0.75rem;
		font-weight: 600;
		text-transform: uppercase;
	}

	.status-badge.active {
		background: #4caf50;
		color: white;
	}

	.status-badge.inactive,
	.status-badge.expired {
		background: #999;
		color: white;
	}

	.status-badge.completed {
		background: #2196f3;
		color: white;
	}

	.messages-list {
		display: grid;
		gap: 12px;
	}

	.message-card {
		padding: 15px;
		background: #f8f9fa;
		border-radius: 8px;
		border-left: 4px solid #667eea;
	}

	.message-header {
		display: flex;
		justify-content: space-between;
		margin-bottom: 10px;
		font-size: 0.85rem;
		color: #666;
	}

	.message-text {
		color: #333;
		line-height: 1.5;
	}

	.empty-state {
		text-align: center;
		padding: 40px;
		color: #999;
		font-style: italic;
	}

	@media (max-width: 768px) {
		.detail-grid {
			grid-template-columns: 1fr;
		}

		.list-grid {
			grid-template-columns: 1fr;
		}
	}
</style>
