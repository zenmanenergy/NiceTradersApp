<script>
	import SuperFetch from '../../SuperFetch.js';
	import { transactionDetailState, viewState } from '../../lib/adminStore.js';
	import { formatDate, formatCurrency } from '../../lib/adminUtils.js';
	
	function viewUser(userId, userName) {
		viewState.update(state => ({
			...state,
			breadcrumbs: [...state.breadcrumbs, { type: 'user', id: userId, label: userName }]
		}));
	}
	
	function viewListing(listingId, listingName) {
		viewState.update(state => ({
			...state,
			breadcrumbs: [...state.breadcrumbs, { type: 'listing', id: listingId, label: listingName }]
		}));
	}
</script>

{#if $transactionDetailState.currentTransaction}
	<div class="detail-view">
		<div class="detail-header">
			<h2>💰 Transaction Details</h2>
			<span class="badge {$transactionDetailState.currentTransaction.status}">{$transactionDetailState.currentTransaction.status}</span>
		</div>
		
		<div class="detail-grid">
			<div class="info-card">
				<h3>Payment Information</h3>
				<div class="info-row"><strong>Amount Paid:</strong> {formatCurrency($transactionDetailState.currentTransaction.amount_paid, $transactionDetailState.currentTransaction.currency)}</div>
				<div class="info-row"><strong>Payment Method:</strong> {$transactionDetailState.currentTransaction.payment_method}</div>
				<div class="info-row"><strong>Transaction ID:</strong> {$transactionDetailState.currentTransaction.transaction_id || '-'}</div>
				<div class="info-row"><strong>Purchased:</strong> {formatDate($transactionDetailState.currentTransaction.purchased_at)}</div>
				<div class="info-row"><strong>Expires:</strong> {formatDate($transactionDetailState.currentTransaction.expires_at) || 'Never'}</div>
			</div>
			
			<div class="info-card">
				<h3>Exchange Rate Info</h3>
				<div class="info-row"><strong>From Currency:</strong> {$transactionDetailState.currentTransaction.from_currency || '-'}</div>
				<div class="info-row"><strong>To Currency:</strong> {$transactionDetailState.currentTransaction.to_currency || '-'}</div>
				<div class="info-row"><strong>Exchange Rate:</strong> {$transactionDetailState.currentTransaction.exchange_rate || '-'}</div>
				<div class="info-row"><strong>Locked Amount:</strong> {$transactionDetailState.currentTransaction.locked_amount ? formatCurrency($transactionDetailState.currentTransaction.locked_amount, $transactionDetailState.currentTransaction.to_currency) : '-'}</div>
				<div class="info-row"><strong>Rate Date:</strong> {$transactionDetailState.currentTransaction.rate_calculation_date || '-'}</div>
			</div>
		</div>

		<div class="section">
			<h3>👥 Parties Involved</h3>
			<div class="detail-grid">
				{#if $transactionDetailState.transactionBuyer}
					<div class="info-card clickable" on:click={() => viewUser($transactionDetailState.transactionBuyer.UserId, `${$transactionDetailState.transactionBuyer.FirstName} ${$transactionDetailState.transactionBuyer.LastName}`)}>
						<h4>💳 Buyer</h4>
						<div class="info-row"><strong>Name:</strong> {$transactionDetailState.transactionBuyer.FirstName} {$transactionDetailState.transactionBuyer.LastName}</div>
						<div class="info-row"><strong>Email:</strong> {$transactionDetailState.transactionBuyer.Email}</div>
						<div class="info-row"><strong>Rating:</strong> {$transactionDetailState.transactionBuyer.Rating} ⭐</div>
						<div class="click-hint">Click to view user →</div>
					</div>
				{/if}

				{#if $transactionDetailState.transactionSeller}
					<div class="info-card clickable" on:click={() => viewUser($transactionDetailState.transactionSeller.UserId, `${$transactionDetailState.transactionSeller.FirstName} ${$transactionDetailState.transactionSeller.LastName}`)}>
						<h4>💰 Seller</h4>
						<div class="info-row"><strong>Name:</strong> {$transactionDetailState.transactionSeller.FirstName} {$transactionDetailState.transactionSeller.LastName}</div>
						<div class="info-row"><strong>Email:</strong> {$transactionDetailState.transactionSeller.Email}</div>
						<div class="info-row"><strong>Rating:</strong> {$transactionDetailState.transactionSeller.Rating} ⭐</div>
						<div class="click-hint">Click to view user →</div>
					</div>
				{/if}
			</div>
		</div>

		{#if $transactionDetailState.transactionListing}
			<div class="section">
				<h3>📋 Related Listing</h3>
				<div class="info-card clickable" on:click={() => viewListing($transactionDetailState.transactionListing.listing_id, `${$transactionDetailState.transactionListing.currency} → ${$transactionDetailState.transactionListing.accept_currency}`)}>
					<div class="info-row"><strong>Exchange:</strong> {$transactionDetailState.transactionListing.currency} → {$transactionDetailState.transactionListing.accept_currency}</div>
					<div class="info-row"><strong>Amount:</strong> {formatCurrency($transactionDetailState.transactionListing.amount, $transactionDetailState.transactionListing.currency)}</div>
					<div class="info-row"><strong>Location:</strong> {$transactionDetailState.transactionListing.location}</div>
					<div class="info-row"><strong>Status:</strong> {$transactionDetailState.transactionListing.status}</div>
					<div class="click-hint">Click to view listing →</div>
				</div>
			</div>
		{/if}
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

	.info-card h3,
	.info-card h4 {
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

	@media (max-width: 768px) {
		.detail-grid {
			grid-template-columns: 1fr;
		}
	}
</style>
