<script>
	import SuperFetch from '../../SuperFetch.js';
	import { formatDate, formatCurrency } from '../../lib/adminUtils.js';
	import AdminLayout from '$lib/AdminLayout.svelte';
	import AdminHeader from '$lib/AdminHeader.svelte';

	let loading = false;
	let error = null;
	let reports = null;
	let stats = null;
	let paymentMethods = [];
	
	// Filter state
	let filters = {
		start_date: '',
		end_date: '',
		payment_method: '',
		status: ''
	};
	
	async function loadReports() {
		loading = true;
		error = null;
		
		try {
			const response = await SuperFetch('/Admin/GetPaymentReports', filters);
			
			if (!response.success) {
				throw new Error(response.error || 'Failed to load payment reports');
			}
			
			reports = response.transactions;
			stats = response.stats;
			paymentMethods = response.payment_methods || [];
		} catch (err) {
			error = err.message;
			console.error('Error loading payment reports:', err);
		} finally {
			loading = false;
		}
	}
	
	function exportToCSV() {
		if (!reports || reports.length === 0) {
			alert('No data to export');
			return;
		}
		
		const headers = ['Date', 'User Name', 'Listing ID', 'Amount', 'Currency', 'Payment Method', 'Status'];
		const rows = reports.map(tx => [
			formatDate(tx.created_at),
			`${tx.FirstName || ''} ${tx.LastName || ''}`,
			tx.listing_id,
			tx.amount,
			tx.currency,
			tx.payment_method,
			tx.payment_status || 'CREATED'
		]);
		
		const csv = [headers, ...rows].map(row => row.map(cell => `"${cell}"`).join(',')).join('\n');
		const blob = new Blob([csv], { type: 'text/csv' });
		const url = window.URL.createObjectURL(blob);
		const a = document.createElement('a');
		a.href = url;
		a.download = `payment-report-${new Date().toISOString().split('T')[0]}.csv`;
		a.click();
	}
	
	function resetFilters() {
		filters = {
			start_date: '',
			end_date: '',
			payment_method: '',
			status: ''
		};
		loadReports();
	}
</script>

<AdminHeader />

<AdminLayout>
	<div class="reports-container">
		<div class="reports-header">
			<h2>💳 Payment Reports</h2>
			<p>View and analyze payment transactions</p>
		</div>
	
	<div class="filter-section">
		<div class="filters">
			<div class="filter-group">
				<label>Start Date</label>
				<input type="date" bind:value={filters.start_date} />
			</div>
			
			<div class="filter-group">
				<label>End Date</label>
				<input type="date" bind:value={filters.end_date} />
			</div>
			
			<div class="filter-group">
				<label>Payment Method</label>
				<select bind:value={filters.payment_method}>
					<option value="">All Methods</option>
					<option value="paypal">PayPal</option>
					<option value="stripe">Stripe</option>
					<option value="crypto">Crypto</option>
				</select>
			</div>
			
			<div class="filter-group">
				<label>Status</label>
				<select bind:value={filters.status}>
					<option value="">All Status</option>
					<option value="completed">Completed</option>
					<option value="pending">Pending</option>
					<option value="failed">Failed</option>
				</select>
			</div>
		</div>
		
		<div class="button-group">
			<button class="btn btn-primary" on:click={loadReports} disabled={loading}>
				{loading ? '🔄 Loading...' : '🔍 Search'}
			</button>
			<button class="btn btn-secondary" on:click={resetFilters}>Reset</button>
			<button class="btn btn-secondary" on:click={exportToCSV} disabled={!reports || reports.length === 0}>
				📥 Export CSV
			</button>
		</div>
	</div>
	
	{#if error}
		<div class="error-message">
			<strong>Error:</strong> {error}
		</div>
	{/if}
	
	{#if stats && reports}
		<div class="stats-grid">
			<div class="stat-card">
				<h4>Total Transactions</h4>
				<p class="stat-value">{stats.total_transactions || 0}</p>
			</div>
			
			<div class="stat-card">
				<h4>Total Amount</h4>
				<p class="stat-value">${(stats.total_amount || 0).toFixed(2)}</p>
			</div>
			
			<div class="stat-card">
				<h4>Average Amount</h4>
				<p class="stat-value">${(stats.average_amount || 0).toFixed(2)}</p>
			</div>
			
			<div class="stat-card">
				<h4>Unique Users</h4>
				<p class="stat-value">{stats.unique_users || 0}</p>
			</div>
			
			<div class="stat-card">
				<h4>Unique Listings</h4>
				<p class="stat-value">{stats.unique_listings || 0}</p>
			</div>
		</div>
		
		{#if paymentMethods && paymentMethods.length > 0}
			<div class="methods-section">
				<h3>Payment Method Breakdown</h3>
				<div class="methods-grid">
					{#each paymentMethods as method}
						<div class="method-card">
							<h5>{method.payment_method || 'Unknown'}</h5>
							<p><strong>{method.count}</strong> transactions</p>
							<p class="amount">${(method.total || 0).toFixed(2)}</p>
						</div>
					{/each}
				</div>
			</div>
		{/if}
		
		<div class="transactions-section">
			<h3>Recent Transactions ({reports.length})</h3>
			
			{#if reports.length > 0}
				<div class="table-container">
					<table class="transactions-table">
						<thead>
							<tr>
								<th>Date</th>
								<th>User ID</th>
								<th>Listing ID</th>
								<th>Amount</th>
								<th>Currency</th>
								<th>Payment Method</th>
								<th>Status</th>
							</tr>
						</thead>
						<tbody>
							{#each reports as transaction}
								<tr>
									<td>{formatDate(transaction.created_at)}</td>
									<td>{transaction.FirstName || ''} {transaction.LastName || ''}</td>
									<td><code>{transaction.listing_id}</code></td>
									<td class="amount">${transaction.amount ? transaction.amount.toFixed(2) : 'N/A'}</td>
									<td>{transaction.currency || 'N/A'}</td>
									<td>{transaction.payment_method || 'N/A'}</td>
									<td>
										<span class="status-badge {(transaction.payment_status || 'CREATED').toLowerCase()}">
											{transaction.payment_status || 'CREATED'}
										</span>
									</td>
								</tr>
							{/each}
						</tbody>
					</table>
				</div>
			{:else}
				<p class="no-data">No transactions found matching the selected filters.</p>
			{/if}
		</div>
	{/if}
</div>
</AdminLayout>

<style>
	.reports-container {
		background: white;
		padding: 30px;
		border-radius: 12px;
		box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
	}
	
	.reports-header {
		margin-bottom: 30px;
		border-bottom: 2px solid #e2e8f0;
		padding-bottom: 20px;
	}
	
	.reports-header h2 {
		margin: 0 0 10px 0;
		color: #2d3748;
		font-size: 1.8rem;
	}
	
	.reports-header p {
		margin: 0;
		color: #718096;
	}
	
	.filter-section {
		background: #f7fafc;
		padding: 20px;
		border-radius: 8px;
		margin-bottom: 30px;
		display: flex;
		flex-direction: column;
		gap: 15px;
	}
	
	.filters {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
		gap: 15px;
	}
	
	.filter-group {
		display: flex;
		flex-direction: column;
	}
	
	.filter-group label {
		font-weight: 600;
		color: #2d3748;
		margin-bottom: 8px;
		font-size: 0.9rem;
	}
	
	.filter-group input,
	.filter-group select {
		padding: 10px;
		border: 1px solid #cbd5e0;
		border-radius: 6px;
		font-size: 0.95rem;
		background: white;
	}
	
	.filter-group input:focus,
	.filter-group select:focus {
		outline: none;
		border-color: #667eea;
		box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
	}
	
	.button-group {
		display: flex;
		gap: 10px;
		flex-wrap: wrap;
	}
	
	.btn {
		padding: 10px 20px;
		border: none;
		border-radius: 6px;
		font-weight: 600;
		cursor: pointer;
		font-size: 0.95rem;
		transition: all 0.2s ease;
	}
	
	.btn:disabled {
		opacity: 0.5;
		cursor: not-allowed;
	}
	
	.btn-primary {
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		color: white;
		box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
	}
	
	.btn-primary:hover:not(:disabled) {
		transform: translateY(-2px);
		box-shadow: 0 6px 20px rgba(102, 126, 234, 0.4);
	}
	
	.btn-secondary {
		background: #e2e8f0;
		color: #2d3748;
	}
	
	.btn-secondary:hover:not(:disabled) {
		background: #cbd5e0;
	}
	
	.error-message {
		background: #fed7d7;
		color: #c53030;
		padding: 15px;
		border-radius: 6px;
		margin-bottom: 20px;
		border-left: 4px solid #c53030;
	}
	
	.stats-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
		gap: 15px;
		margin-bottom: 30px;
	}
	
	.stat-card {
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		color: white;
		padding: 20px;
		border-radius: 8px;
		text-align: center;
		box-shadow: 0 4px 15px rgba(102, 126, 234, 0.2);
	}
	
	.stat-card h4 {
		margin: 0 0 10px 0;
		font-size: 0.9rem;
		opacity: 0.9;
	}
	
	.stat-value {
		margin: 0;
		font-size: 1.8rem;
		font-weight: bold;
	}
	
	.methods-section {
		margin-bottom: 30px;
	}
	
	.methods-section h3 {
		margin: 0 0 15px 0;
		color: #2d3748;
		font-size: 1.2rem;
	}
	
	.methods-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
		gap: 15px;
	}
	
	.method-card {
		background: #f7fafc;
		border: 1px solid #e2e8f0;
		padding: 15px;
		border-radius: 8px;
		text-align: center;
	}
	
	.method-card h5 {
		margin: 0 0 10px 0;
		text-transform: capitalize;
		color: #2d3748;
	}
	
	.method-card p {
		margin: 5px 0;
		color: #718096;
		font-size: 0.9rem;
	}
	
	.method-card .amount {
		font-weight: bold;
		color: #667eea;
		font-size: 1rem;
	}
	
	.transactions-section h3 {
		margin: 0 0 15px 0;
		color: #2d3748;
		font-size: 1.2rem;
	}
	
	.table-container {
		overflow-x: auto;
		border: 1px solid #e2e8f0;
		border-radius: 8px;
	}
	
	.transactions-table {
		width: 100%;
		border-collapse: collapse;
		font-size: 0.9rem;
	}
	
	.transactions-table thead {
		background: #f7fafc;
		border-bottom: 2px solid #e2e8f0;
	}
	
	.transactions-table th {
		padding: 12px;
		text-align: left;
		font-weight: 600;
		color: #2d3748;
	}
	
	.transactions-table td {
		padding: 12px;
		border-bottom: 1px solid #e2e8f0;
		color: #4a5568;
	}
	
	.transactions-table tbody tr:hover {
		background: #f7fafc;
	}
	
	.transactions-table code {
		background: #edf2f7;
		padding: 2px 6px;
		border-radius: 3px;
		font-family: 'Monaco', 'Menlo', monospace;
		font-size: 0.85rem;
		color: #5a67d8;
	}
	
	.amount {
		text-align: right;
		font-weight: 600;
		color: #667eea;
	}
	
	.status-badge {
		display: inline-block;
		padding: 4px 12px;
		border-radius: 20px;
		font-size: 0.8rem;
		font-weight: 600;
		text-transform: uppercase;
	}
	
	.status-badge.completed {
		background: #c6f6d5;
		color: #22543d;
	}
	
	.status-badge.pending {
		background: #fed7aa;
		color: #7c2d12;
	}
	
	.status-badge.failed {
		background: #fed7d7;
		color: #742a2a;
	}
	
	.no-data {
		text-align: center;
		color: #718096;
		padding: 20px;
		font-style: italic;
	}
</style>
