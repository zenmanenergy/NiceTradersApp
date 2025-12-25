<script>
	import { onMount } from 'svelte';
	import SuperFetch from '../../SuperFetch.js';
	import { formatDate, formatCurrency } from '../../lib/adminUtils.js';
	import AdminLayout from '$lib/AdminLayout.svelte';
	import AdminHeader from '$lib/AdminHeader.svelte';

	let loading = false;
	let error = null;
	let transactions = [];
	let stats = null;
	let selectedTransaction = null;
	let showRefundModal = false;
	let refundReason = '';
	let refundLoading = false;
	let refundError = null;
	let refundSuccess = null;

	// Filter state
	let filters = {
		user_id: '',
		listing_id: '',
		status: 'COMPLETED',
		limit: 50,
		offset: 0
	};

	let currentPage = 1;
	let totalCount = 0;
	let pageSize = 50;

	async function loadTransactions() {
		loading = true;
		error = null;

		try {
			const response = await SuperFetch('/Admin/GetPayPalTransactions', filters);

			if (!response.success) {
				throw new Error(response.error || 'Failed to load PayPal transactions');
			}

			transactions = response.transactions || [];
			totalCount = response.total_count || 0;

			// Calculate stats
			stats = {
				total_transactions: transactions.length,
				total_amount: transactions.reduce((sum, tx) => sum + (parseFloat(tx.paypal_amount) || 0), 0),
				completed: transactions.filter(tx => tx.status === 'COMPLETED').length,
				refunded: transactions.filter(tx => tx.status === 'REFUNDED').length
			};
		} catch (err) {
			error = err.message;
			console.error('Error loading PayPal transactions:', err);
		} finally {
			loading = false;
		}
	}

	async function refundTransaction(transaction) {
		if (!refundReason.trim()) {
			refundError = 'Please provide a refund reason';
			return;
		}

		refundLoading = true;
		refundError = null;
		refundSuccess = null;

		try {
			const response = await SuperFetch('/Admin/RefundPayPalTransaction', {
				order_id: transaction.order_id,
				reason: refundReason
			});

			if (!response.success) {
				throw new Error(response.error || 'Failed to refund transaction');
			}

			refundSuccess = `Refunded $${transaction.paypal_amount} to ${transaction.user_first_name} ${transaction.user_last_name}`;
			refundReason = '';
			selectedTransaction = null;
			showRefundModal = false;

			// Reload transactions
			setTimeout(() => {
				loadTransactions();
			}, 1500);
		} catch (err) {
			refundError = err.message;
			console.error('Error refunding transaction:', err);
		} finally {
			refundLoading = false;
		}
	}

	function openRefundModal(transaction) {
		selectedTransaction = transaction;
		refundReason = '';
		refundError = null;
		showRefundModal = true;
	}

	function closeRefundModal() {
		showRefundModal = false;
		selectedTransaction = null;
		refundReason = '';
		refundError = null;
	}

	function previousPage() {
		if (currentPage > 1) {
			currentPage--;
			filters.offset = (currentPage - 1) * pageSize;
			loadTransactions();
		}
	}

	function nextPage() {
		if (currentPage * pageSize < totalCount) {
			currentPage++;
			filters.offset = (currentPage - 1) * pageSize;
			loadTransactions();
		}
	}

	function handleFilterChange() {
		currentPage = 1;
		filters.offset = 0;
		loadTransactions();
	}

	function exportToCSV() {
		if (!transactions || transactions.length === 0) {
			alert('No data to export');
			return;
		}

		const headers = [
			'Order ID',
			'User',
			'Email',
			'Listing ID',
			'Amount',
			'Currency',
			'Status',
			'Payer Name',
			'Created'
		];

		const rows = transactions.map(tx => [
			tx.order_id,
			`${tx.user_first_name} ${tx.user_last_name}`,
			tx.user_email,
			tx.listing_id || 'N/A',
			tx.paypal_amount,
			tx.paypal_currency,
			tx.status,
			tx.payer_name || 'N/A',
			formatDate(tx.created_at)
		]);

		const csvContent = [
			headers.join(','),
			...rows.map(row => row.map(cell => `"${cell}"`).join(','))
		].join('\n');

		const blob = new Blob([csvContent], { type: 'text/csv' });
		const url = window.URL.createObjectURL(blob);
		const a = document.createElement('a');
		a.href = url;
		a.download = `paypal-transactions-${new Date().toISOString().split('T')[0]}.csv`;
		a.click();
		window.URL.revokeObjectURL(url);
	}

	onMount(() => {
		loadTransactions();
	});
</script>

<AdminHeader />

<AdminLayout pageTitle="PayPal Transactions">
	<div class="container">
		<!-- Header -->
		<div class="header">
			<h1>PayPal Transactions</h1>
			<button class="btn btn-primary" on:click={exportToCSV} disabled={!transactions || transactions.length === 0}>
				📥 Export CSV
			</button>
		</div>

		<!-- Error Message -->
		{#if error}
			<div class="alert alert-danger">{error}</div>
		{/if}

		{#if refundSuccess}
			<div class="alert alert-success">{refundSuccess}</div>
		{/if}

		<!-- Stats -->
		{#if stats}
			<div class="stats-grid">
				<div class="stat-card">
					<h4>Total Transactions</h4>
					<p class="stat-value">{stats.total_transactions}</p>
				</div>
				<div class="stat-card">
					<h4>Total Amount</h4>
					<p class="stat-value">${stats.total_amount.toFixed(2)}</p>
				</div>
				<div class="stat-card">
					<h4>Completed</h4>
					<p class="stat-value">{stats.completed}</p>
				</div>
				<div class="stat-card">
					<h4>Refunded</h4>
					<p class="stat-value">{stats.refunded}</p>
				</div>
			</div>
		{/if}

		<!-- Filters -->
		<div class="filters">
			<div class="filter-group">
				<label>Status</label>
				<select bind:value={filters.status} on:change={handleFilterChange}>
					<option value="">All</option>
					<option value="CREATED">Created</option>
					<option value="APPROVED">Approved</option>
					<option value="COMPLETED">Completed</option>
					<option value="FAILED">Failed</option>
					<option value="REFUNDED">Refunded</option>
				</select>
			</div>

			<div class="filter-group">
				<label>User ID</label>
				<input
					type="text"
					placeholder="Filter by user ID..."
					bind:value={filters.user_id}
					on:change={handleFilterChange}
				/>
			</div>

			<div class="filter-group">
				<label>Listing ID</label>
				<input
					type="text"
					placeholder="Filter by listing ID..."
					bind:value={filters.listing_id}
					on:change={handleFilterChange}
				/>
			</div>
		</div>

		<!-- Loading State -->
		{#if loading}
			<div class="loading">Loading PayPal transactions...</div>
		{:else if transactions && transactions.length > 0}
			<!-- Transactions Table -->
			<div class="table-container">
				<table>
					<thead>
						<tr>
							<th>Order ID</th>
							<th>User</th>
							<th>Email</th>
							<th>Listing ID</th>
							<th>Amount</th>
							<th>Status</th>
							<th>Created</th>
							<th>Actions</th>
						</tr>
					</thead>
					<tbody>
						{#each transactions as transaction}
							<tr>
								<td class="monospace">{transaction.order_id.substring(0, 12)}...</td>
								<td>{transaction.user_first_name} {transaction.user_last_name}</td>
								<td>{transaction.user_email}</td>
								<td class="monospace">{transaction.listing_id ? transaction.listing_id.substring(0, 12) + '...' : 'N/A'}</td>
								<td>
									<strong>${transaction.paypal_amount?.toFixed(2) || '0.00'}</strong>
									<small>{transaction.paypal_currency}</small>
								</td>
								<td>
									<span class={`status status-${transaction.status.toLowerCase()}`}>
										{transaction.status}
									</span>
								</td>
								<td class="text-muted">{formatDate(transaction.created_at)}</td>
								<td>
									{#if transaction.status === 'COMPLETED'}
										<button
											class="btn btn-sm btn-danger"
											on:click={() => openRefundModal(transaction)}
											title="Refund this transaction"
										>
											💳 Refund
										</button>
									{:else if transaction.status === 'REFUNDED'}
										<span class="badge badge-success">✓ Refunded</span>
									{:else}
										<span class="badge badge-secondary">{transaction.status}</span>
									{/if}
								</td>
							</tr>
						{/each}
					</tbody>
				</table>
			</div>

			<!-- Pagination -->
			<div class="pagination">
				<button
					class="btn btn-secondary"
					on:click={previousPage}
					disabled={currentPage === 1 || loading}
				>
					← Previous
				</button>
				<span class="page-info">
					Page {currentPage} of {Math.ceil(totalCount / pageSize)}
					({totalCount} total transactions)
				</span>
				<button
					class="btn btn-secondary"
					on:click={nextPage}
					disabled={currentPage * pageSize >= totalCount || loading}
				>
					Next →
				</button>
			</div>
		{:else}
			<div class="empty-state">
				<p>No PayPal transactions found</p>
				<button class="btn btn-secondary" on:click={loadTransactions}>Refresh</button>
			</div>
		{/if}
	</div>

	<!-- Refund Modal -->
	{#if showRefundModal && selectedTransaction}
		<div class="modal-overlay" on:click={closeRefundModal}>
			<div class="modal" on:click|stopPropagation>
				<div class="modal-header">
					<h2>Refund PayPal Transaction</h2>
					<button class="close-btn" on:click={closeRefundModal}>&times;</button>
				</div>

				<div class="modal-body">
					<div class="transaction-details">
						<div class="detail-row">
							<strong>Order ID:</strong>
							<span class="monospace">{selectedTransaction.order_id}</span>
						</div>
						<div class="detail-row">
							<strong>User:</strong>
							<span>{selectedTransaction.user_first_name} {selectedTransaction.user_last_name}</span>
						</div>
						<div class="detail-row">
							<strong>Amount:</strong>
							<span class="highlight">${selectedTransaction.paypal_amount?.toFixed(2) || '0.00'} {selectedTransaction.paypal_currency}</span>
						</div>
						<div class="detail-row">
							<strong>Payer:</strong>
							<span>{selectedTransaction.payer_name || 'N/A'}</span>
						</div>
						<div class="detail-row">
							<strong>Created:</strong>
							<span>{formatDate(selectedTransaction.created_at)}</span>
						</div>
					</div>

					{#if refundError}
						<div class="alert alert-danger">{refundError}</div>
					{/if}

					<div class="form-group">
						<label for="refund-reason">Refund Reason *</label>
						<textarea
							id="refund-reason"
							placeholder="Enter reason for refund (e.g., User requested refund, Service not provided, etc.)"
							bind:value={refundReason}
							rows="4"
						/>
					</div>

					<div class="alert alert-info">
						<strong>Note:</strong> This will issue a credit to the user's account. They can use this credit
						for future payments.
					</div>
				</div>

				<div class="modal-footer">
					<button
						class="btn btn-secondary"
						on:click={closeRefundModal}
						disabled={refundLoading}
					>
						Cancel
					</button>
					<button
						class="btn btn-danger"
						on:click={() => refundTransaction(selectedTransaction)}
						disabled={refundLoading || !refundReason.trim()}
					>
						{#if refundLoading}
							⏳ Processing...
						{:else}
							🔄 Confirm Refund
						{/if}
					</button>
				</div>
			</div>
		</div>
	{/if}
</AdminLayout>

<style>
	.container {
		padding: 2rem;
	}

	.header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 2rem;
	}

	.header h1 {
		margin: 0;
		font-size: 1.8rem;
	}

	.alert {
		padding: 1rem;
		margin-bottom: 1rem;
		border-radius: 0.5rem;
		animation: slideIn 0.3s ease-out;
	}

	.alert-danger {
		background-color: #fee;
		border-left: 4px solid #d32f2f;
		color: #d32f2f;
	}

	.alert-success {
		background-color: #efe;
		border-left: 4px solid #388e3c;
		color: #388e3c;
	}

	.alert-info {
		background-color: #efe;
		border-left: 4px solid #1976d2;
		color: #1976d2;
	}

	@keyframes slideIn {
		from {
			opacity: 0;
			transform: translateY(-10px);
		}
		to {
			opacity: 1;
			transform: translateY(0);
		}
	}

	.stats-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
		gap: 1rem;
		margin-bottom: 2rem;
	}

	.stat-card {
		background: white;
		padding: 1.5rem;
		border-radius: 0.5rem;
		box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
	}

	.stat-card h4 {
		margin: 0 0 0.5rem 0;
		color: #666;
		font-size: 0.9rem;
		text-transform: uppercase;
	}

	.stat-value {
		margin: 0;
		font-size: 1.8rem;
		font-weight: bold;
		color: #333;
	}

	.filters {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
		gap: 1rem;
		margin-bottom: 2rem;
		background: white;
		padding: 1.5rem;
		border-radius: 0.5rem;
		box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
	}

	.filter-group {
		display: flex;
		flex-direction: column;
	}

	.filter-group label {
		font-weight: 600;
		margin-bottom: 0.5rem;
		color: #333;
		font-size: 0.9rem;
	}

	.filter-group input,
	.filter-group select {
		padding: 0.5rem;
		border: 1px solid #ddd;
		border-radius: 0.3rem;
		font-size: 0.9rem;
	}

	.filter-group input:focus,
	.filter-group select:focus {
		outline: none;
		border-color: #1976d2;
		box-shadow: 0 0 0 2px rgba(25, 118, 210, 0.1);
	}

	.loading {
		text-align: center;
		padding: 3rem;
		color: #999;
	}

	.empty-state {
		text-align: center;
		padding: 3rem;
		background: white;
		border-radius: 0.5rem;
		color: #999;
	}

	.table-container {
		background: white;
		border-radius: 0.5rem;
		box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
		overflow: hidden;
	}

	table {
		width: 100%;
		border-collapse: collapse;
	}

	thead {
		background-color: #f5f5f5;
	}

	th {
		padding: 1rem;
		text-align: left;
		font-weight: 600;
		color: #333;
		border-bottom: 2px solid #ddd;
		white-space: nowrap;
		font-size: 0.9rem;
	}

	td {
		padding: 1rem;
		border-bottom: 1px solid #eee;
	}

	tbody tr:hover {
		background-color: #f9f9f9;
	}

	.monospace {
		font-family: 'Courier New', monospace;
		font-size: 0.85rem;
		color: #666;
	}

	.text-muted {
		color: #999;
		font-size: 0.9rem;
	}

	.status {
		display: inline-block;
		padding: 0.25rem 0.75rem;
		border-radius: 0.25rem;
		font-size: 0.85rem;
		font-weight: 600;
		text-transform: uppercase;
	}

	.status-completed {
		background-color: #e8f5e9;
		color: #2e7d32;
	}

	.status-refunded {
		background-color: #fff3e0;
		color: #f57f17;
	}

	.status-failed {
		background-color: #ffebee;
		color: #c62828;
	}

	.status-created,
	.status-approved {
		background-color: #e3f2fd;
		color: #1565c0;
	}

	.badge {
		display: inline-block;
		padding: 0.25rem 0.75rem;
		border-radius: 0.25rem;
		font-size: 0.85rem;
		font-weight: 600;
	}

	.badge-success {
		background-color: #e8f5e9;
		color: #2e7d32;
	}

	.badge-secondary {
		background-color: #f5f5f5;
		color: #666;
	}

	.btn {
		padding: 0.5rem 1rem;
		border: none;
		border-radius: 0.3rem;
		cursor: pointer;
		font-size: 0.9rem;
		font-weight: 600;
		transition: all 0.2s;
	}

	.btn:disabled {
		opacity: 0.5;
		cursor: not-allowed;
	}

	.btn-primary {
		background-color: #1976d2;
		color: white;
	}

	.btn-primary:hover:not(:disabled) {
		background-color: #1565c0;
	}

	.btn-secondary {
		background-color: #757575;
		color: white;
	}

	.btn-secondary:hover:not(:disabled) {
		background-color: #616161;
	}

	.btn-danger {
		background-color: #d32f2f;
		color: white;
	}

	.btn-danger:hover:not(:disabled) {
		background-color: #c62828;
	}

	.btn-sm {
		padding: 0.3rem 0.6rem;
		font-size: 0.8rem;
	}

	.pagination {
		display: flex;
		justify-content: center;
		align-items: center;
		gap: 1rem;
		margin-top: 2rem;
		padding: 1rem;
	}

	.page-info {
		color: #666;
		font-size: 0.9rem;
	}

	/* Modal Styles */
	.modal-overlay {
		position: fixed;
		top: 0;
		left: 0;
		right: 0;
		bottom: 0;
		background-color: rgba(0, 0, 0, 0.5);
		display: flex;
		align-items: center;
		justify-content: center;
		z-index: 1000;
	}

	.modal {
		background: white;
		border-radius: 0.5rem;
		box-shadow: 0 20px 25px rgba(0, 0, 0, 0.15);
		max-width: 500px;
		width: 90%;
		max-height: 90vh;
		overflow-y: auto;
		animation: modalSlideIn 0.3s ease-out;
	}

	@keyframes modalSlideIn {
		from {
			opacity: 0;
			transform: scale(0.95);
		}
		to {
			opacity: 1;
			transform: scale(1);
		}
	}

	.modal-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		padding: 1.5rem;
		border-bottom: 1px solid #eee;
	}

	.modal-header h2 {
		margin: 0;
		font-size: 1.3rem;
	}

	.close-btn {
		background: none;
		border: none;
		font-size: 2rem;
		cursor: pointer;
		color: #999;
		line-height: 1;
		padding: 0;
	}

	.close-btn:hover {
		color: #333;
	}

	.modal-body {
		padding: 1.5rem;
	}

	.modal-footer {
		padding: 1.5rem;
		border-top: 1px solid #eee;
		display: flex;
		justify-content: flex-end;
		gap: 1rem;
	}

	.transaction-details {
		background-color: #f9f9f9;
		padding: 1rem;
		border-radius: 0.3rem;
		margin-bottom: 1.5rem;
	}

	.detail-row {
		display: flex;
		justify-content: space-between;
		padding: 0.5rem 0;
		border-bottom: 1px solid #eee;
	}

	.detail-row:last-child {
		border-bottom: none;
	}

	.detail-row strong {
		color: #666;
		min-width: 100px;
	}

	.highlight {
		font-weight: bold;
		color: #d32f2f;
		font-size: 1.1rem;
	}

	.form-group {
		margin-bottom: 1.5rem;
	}

	.form-group label {
		display: block;
		font-weight: 600;
		margin-bottom: 0.5rem;
		color: #333;
	}

	.form-group textarea {
		width: 100%;
		padding: 0.75rem;
		border: 1px solid #ddd;
		border-radius: 0.3rem;
		font-family: inherit;
		font-size: 0.9rem;
		resize: vertical;
	}

	.form-group textarea:focus {
		outline: none;
		border-color: #1976d2;
		box-shadow: 0 0 0 2px rgba(25, 118, 210, 0.1);
	}
</style>
