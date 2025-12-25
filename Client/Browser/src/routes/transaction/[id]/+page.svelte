<script>
	import { formatDate, formatCurrency } from '../../../lib/adminUtils.js';
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';
	import AdminLayout from '$lib/AdminLayout.svelte';
	import AdminHeader from '$lib/AdminHeader.svelte';
	import { onMount } from 'svelte';
	
	let transaction = null;
	let transactionBuyer = null;
	let transactionSeller = null;
	let transactionListing = null;
	let loading = true;
	let error = null;
	
	onMount(async () => {
		await loadTransactionData();
	});
	
	async function loadTransactionData() {
		loading = true;
		error = null;
		
		try {
			const transactionId = $page.params.id;
			const API_URL = 'https://api.nicetraders.net';
			
			// Fetch transaction data
			const txRes = await fetch(`${API_URL}/Admin/GetTransactionById`, {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ transactionId })
			});
			const txData = await txRes.json();
			
			if (!txData.success) {
				throw new Error('Transaction not found');
			}
			
			transaction = txData.transaction;
			
			// Fetch buyer
			if (transaction.user_id) {
				const buyerRes = await fetch(`${API_URL}/Admin/GetUserById`, {
					method: 'POST',
					headers: { 'Content-Type': 'application/json' },
					body: JSON.stringify({ user_id: transaction.user_id })
				});
				const buyerData = await buyerRes.json();
				if (buyerData.success) {
					transactionBuyer = buyerData.user;
				}
			}
			
			// Fetch listing and seller
			if (transaction.listing_id) {
				const listingRes = await fetch(`${API_URL}/Admin/GetListingById`, {
					method: 'POST',
					headers: { 'Content-Type': 'application/json' },
					body: JSON.stringify({ listingId: transaction.listing_id })
				});
				const listingData = await listingRes.json();
				
				if (listingData.success) {
					transactionListing = listingData.listing;
					
					// Fetch seller
					if (listingData.listing.user_id) {
						const sellerRes = await fetch(`${API_URL}/Admin/GetUserById`, {
							method: 'POST',
							headers: { 'Content-Type': 'application/json' },
							body: JSON.stringify({ user_id: listingData.listing.user_id })
						});
						const sellerData = await sellerRes.json();
						if (sellerData.success) {
							transactionSeller = sellerData.user;
						}
					}
				}
			}
		} catch (err) {
			console.error('Error loading transaction:', err);
			error = err.message || 'Failed to load transaction';
		} finally {
			loading = false;
		}
	}
	
	function viewUser(userId) {
		goto(`/user/${userId}`);
	}
	
	function viewListing(listingId) {
		goto(`/listing/${listingId}`);
	}
</script>

<AdminHeader />

{#if transaction}
	<div class="detail-view">
		<div class="detail-header">
			<h2>💰 Transaction Details</h2>
			<span class="badge {transaction.status}">{transaction.status}</span>
		</div>
		
		<div class="detail-grid">
			<div class="info-card">
				<h3>Payment Information</h3>
				<div class="info-row"><strong>Amount Paid:</strong> {formatCurrency(transaction.amount_paid, transaction.currency)}</div>
				<div class="info-row"><strong>Payment Method:</strong> {transaction.payment_method}</div>
				<div class="info-row"><strong>Transaction ID:</strong> {transaction.transaction_id || '-'}</div>
				<div class="info-row"><strong>Purchased:</strong> {formatDate(transaction.purchased_at)}</div>
				<div class="info-row"><strong>Expires:</strong> {formatDate(transaction.expires_at) || 'Never'}</div>
			</div>
			
			<div class="info-card">
				<h3>Exchange Rate Info</h3>
				<div class="info-row"><strong>From Currency:</strong> {transaction.from_currency || '-'}</div>
				<div class="info-row"><strong>To Currency:</strong> {transaction.to_currency || '-'}</div>
				<div class="info-row"><strong>Exchange Rate:</strong> {transaction.exchange_rate || '-'}</div>
				<div class="info-row"><strong>Locked Amount:</strong> {transaction.locked_amount ? formatCurrency(transaction.locked_amount, transaction.to_currency) : '-'}</div>
				<div class="info-row"><strong>Rate Date:</strong> {transaction.rate_calculation_date || '-'}</div>
			</div>
		</div>

		<div class="section">
			<h3>👥 Parties Involved</h3>
			<div class="detail-grid">
				{#if transactionBuyer}
					<div class="info-card clickable" on:click={() => viewUser(transactionBuyer.user_id)}>
						<h4>💳 Buyer</h4>
						<div class="info-row"><strong>Name:</strong> {transactionBuyer.FirstName} {transactionBuyer.LastName}</div>
						<div class="info-row"><strong>Email:</strong> {transactionBuyer.Email}</div>
						<div class="info-row"><strong>Rating:</strong> {transactionBuyer.Rating} ⭐</div>
						<div class="click-hint">Click to view user →</div>
					</div>
				{/if}

				{#if transactionSeller}
					<div class="info-card clickable" on:click={() => viewUser(transactionSeller.user_id)}>
						<h4>💰 Seller</h4>
						<div class="info-row"><strong>Name:</strong> {transactionSeller.FirstName} {transactionSeller.LastName}</div>
						<div class="info-row"><strong>Email:</strong> {transactionSeller.Email}</div>
						<div class="info-row"><strong>Rating:</strong> {transactionSeller.Rating} ⭐</div>
						<div class="click-hint">Click to view user →</div>
					</div>
				{/if}
			</div>
		</div>

		{#if transactionListing}
			<div class="section">
				<h3>📋 Related Listing</h3>
				<div class="info-card clickable" on:click={() => viewListing(transactionListing.listing_id)}>
					<div class="info-row"><strong>Exchange:</strong> {transactionListing.currency} → {transactionListing.accept_currency}</div>
					<div class="info-row"><strong>Amount:</strong> {formatCurrency(transactionListing.amount, transactionListing.currency)}</div>
					<div class="info-row"><strong>Location:</strong> {transactionListing.location}</div>
					<div class="info-row"><strong>Status:</strong> {transactionListing.status}</div>
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
