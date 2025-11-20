<script>
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';
	import { Session } from '../../Session.js';
	import { handleGetExchangeHistory } from '../profile/handleProfile.js';
	
	// Exchange history data
	let exchangeHistory = [];
	let filteredHistory = [];
	let isLoading = true;
	
	// Filter options
	let filters = {
		type: 'all', // 'all', 'bought', 'sold'
		currency: 'all',
		status: 'all',
		timeframe: 'all' // 'all', '30days', '90days', '1year'
	};
	
	// Available currencies (extracted from exchange data)
	let availableCurrencies = [];
	
	function goBack() {
		goto('/profile');
	}
	
	function filterHistory() {
		filteredHistory = exchangeHistory.filter(exchange => {
			// Type filter
			if (filters.type !== 'all' && exchange.type !== filters.type) {
				return false;
			}
			
			// Currency filter
			if (filters.currency !== 'all' && exchange.currency !== filters.currency) {
				return false;
			}
			
			// Status filter
			if (filters.status !== 'all' && exchange.status !== filters.status) {
				return false;
			}
			
			// Timeframe filter
			if (filters.timeframe !== 'all') {
				const exchangeDate = new Date(exchange.date);
				const now = new Date();
				const daysDiff = Math.floor((now - exchangeDate) / (1000 * 60 * 60 * 24));
				
				switch (filters.timeframe) {
					case '30days':
						if (daysDiff > 30) return false;
						break;
					case '90days':
						if (daysDiff > 90) return false;
						break;
					case '1year':
						if (daysDiff > 365) return false;
						break;
				}
			}
			
			return true;
		});
	}
	
	function clearFilters() {
		filters = {
			type: 'all',
			currency: 'all',
			status: 'all',
			timeframe: 'all'
		};
		filterHistory();
	}
	
	function viewExchange(exchangeId) {
		goto(`/exchange/${exchangeId}`);
	}
	
	function formatDate(dateString) {
		const date = new Date(dateString);
		return date.toLocaleDateString('en-US', {
			year: 'numeric',
			month: 'short',
			day: 'numeric'
		});
	}
	
	function getStatusColor(status) {
		switch (status) {
			case 'completed': return '#10b981';
			case 'pending': return '#f59e0b';
			case 'cancelled': return '#ef4444';
			default: return '#6b7280';
		}
	}
	
	function getTypeIcon(type) {
		return type === 'bought' ? '📥' : '📤';
	}
	
	// Reactive statement to filter history when filters change
	$: if (filters) {
		filterHistory();
	}
	
	onMount(async () => {
		await Session.handleSession();
		Session.GetSessionId(); // This sets Session.SessionId
		const sessionId = Session.SessionId;
		
		if (!sessionId) {
			goto('/login');
			return;
		}
		
		handleGetExchangeHistory(sessionId, (result) => {
			isLoading = false;
			if (result && result.success && result.exchanges) {
				exchangeHistory = result.exchanges;
				filteredHistory = [...exchangeHistory];
				
				// Extract unique currencies for filter dropdown
				availableCurrencies = [...new Set(exchangeHistory.map(ex => ex.currency))].sort();
				
				console.log('Exchange history loaded:', exchangeHistory.length, 'exchanges');
			} else {
				console.error('Failed to load exchange history:', result?.error);
				// Use empty array if no data
				exchangeHistory = [];
				filteredHistory = [];
			}
		});
	});
</script>

<svelte:head>
	<title>Exchange History - NICE Traders</title>
	<meta name="description" content="View your complete currency exchange history" />
</svelte:head>

<main class="history-container">
	<div class="header">
		<button class="back-button" on:click={goBack} aria-label="Go back to profile">
			<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
				<polyline points="15,18 9,12 15,6"></polyline>
			</svg>
		</button>
		<h1 class="page-title">Exchange History</h1>
		<div class="spacer"></div>
	</div>

	<div class="content">
		<!-- Summary Stats -->
		<section class="summary-section">
			<div class="summary-cards">
				<div class="summary-card">
					<div class="summary-number">{exchangeHistory.length}</div>
					<div class="summary-label">Total Exchanges</div>
				</div>
				<div class="summary-card">
					<div class="summary-number">{exchangeHistory.filter(ex => ex.status === 'completed').length}</div>
					<div class="summary-label">Completed</div>
				</div>
				<div class="summary-card">
					<div class="summary-number">{exchangeHistory.filter(ex => ex.type === 'bought').length}</div>
					<div class="summary-label">Bought</div>
				</div>
				<div class="summary-card">
					<div class="summary-number">{exchangeHistory.filter(ex => ex.type === 'sold').length}</div>
					<div class="summary-label">Sold</div>
				</div>
			</div>
		</section>

		<!-- Filters -->
		<section class="filters-section">
			<div class="filters-header">
				<h3>Filter History</h3>
				<button class="clear-filters-btn" on:click={clearFilters}>Clear All</button>
			</div>
			
			<div class="filters-grid">
				<div class="filter-group">
					<label for="type-filter">Type</label>
					<select id="type-filter" bind:value={filters.type} class="filter-select">
						<option value="all">All Types</option>
						<option value="bought">Bought</option>
						<option value="sold">Sold</option>
					</select>
				</div>
				
				<div class="filter-group">
					<label for="currency-filter">Currency</label>
					<select id="currency-filter" bind:value={filters.currency} class="filter-select">
						<option value="all">All Currencies</option>
						{#each availableCurrencies as currency}
							<option value={currency}>{currency}</option>
						{/each}
					</select>
				</div>
				
				<div class="filter-group">
					<label for="status-filter">Status</label>
					<select id="status-filter" bind:value={filters.status} class="filter-select">
						<option value="all">All Status</option>
						<option value="completed">Completed</option>
						<option value="pending">Pending</option>
						<option value="cancelled">Cancelled</option>
					</select>
				</div>
				
				<div class="filter-group">
					<label for="timeframe-filter">Timeframe</label>
					<select id="timeframe-filter" bind:value={filters.timeframe} class="filter-select">
						<option value="all">All Time</option>
						<option value="30days">Last 30 Days</option>
						<option value="90days">Last 90 Days</option>
						<option value="1year">Last Year</option>
					</select>
				</div>
			</div>
		</section>

		<!-- Exchange History List -->
		<section class="history-section">
			<div class="history-header">
				<h3>Exchanges ({filteredHistory.length})</h3>
			</div>
			
			{#if isLoading}
				<div class="loading-state">
					<div class="loading-spinner"></div>
					<p>Loading exchange history...</p>
				</div>
			{:else if filteredHistory.length === 0}
				<div class="empty-state">
					<div class="empty-icon">📊</div>
					<h4>No exchanges found</h4>
					<p>
						{#if exchangeHistory.length === 0}
							You haven't completed any exchanges yet.
						{:else}
							No exchanges match your current filters.
						{/if}
					</p>
				</div>
			{:else}
				<div class="history-list">
					{#each filteredHistory as exchange}
						<button 
							class="history-item" 
							on:click={() => viewExchange(exchange.id)}
							role="button"
						>
							<div class="exchange-icon">
								{getTypeIcon(exchange.type)}
							</div>
							<div class="exchange-info">
								<div class="exchange-header">
									<span class="currency-badge">{exchange.currency}</span>
									<span class="amount">{exchange.amount.toLocaleString()}</span>
									<div class="status-badge" style="background-color: {getStatusColor(exchange.status)}">
										{exchange.status}
									</div>
								</div>
								<div class="exchange-details">
									<span class="partner">with {exchange.partner}</span>
									<span class="date">{formatDate(exchange.date)}</span>
								</div>
								<div class="exchange-rating">
									<div class="stars">
										{#each Array(5) as _, i}
											<span class="star" class:filled={i < exchange.rating}>⭐</span>
										{/each}
									</div>
								</div>
							</div>
							<div class="exchange-arrow">
								<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
									<polyline points="9,18 15,12 9,6"></polyline>
								</svg>
							</div>
						</button>
					{/each}
				</div>
			{/if}
		</section>
	</div>
</main>

<style>
	.history-container {
		max-width: 414px;
		margin: 0 auto;
		min-height: 100vh;
		background: #f8fafc;
		display: flex;
		flex-direction: column;
		box-shadow: 0 0 20px rgba(0, 0, 0, 0.1);
	}

	.header {
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		color: white;
		padding: 1rem 1.5rem;
		display: flex;
		align-items: center;
		justify-content: space-between;
		min-height: 60px;
		position: sticky;
		top: 0;
		z-index: 10;
	}

	.back-button {
		background: rgba(255, 255, 255, 0.2);
		border: none;
		border-radius: 8px;
		width: 40px;
		height: 40px;
		display: flex;
		align-items: center;
		justify-content: center;
		cursor: pointer;
		transition: background 0.2s;
	}

	.back-button:hover {
		background: rgba(255, 255, 255, 0.3);
	}

	.page-title {
		color: white;
		font-size: 1.5rem;
		font-weight: 600;
		margin: 0 0 0 1rem;
	}

	.spacer {
		flex: 1;
	}

	.content {
		flex: 1;
		padding: 1.5rem;
		overflow-y: auto;
	}

	/* Summary Section */
	.summary-section {
		margin-bottom: 2rem;
	}

	.summary-cards {
		display: grid;
		grid-template-columns: repeat(2, 1fr);
		gap: 1rem;
	}

	.summary-card {
		background: white;
		padding: 1.5rem;
		border-radius: 12px;
		text-align: center;
		box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
	}

	.summary-number {
		font-size: 2rem;
		font-weight: 700;
		color: #667eea;
		margin-bottom: 0.5rem;
	}

	.summary-label {
		font-size: 0.9rem;
		color: #718096;
		font-weight: 500;
	}

	/* Filters Section */
	.filters-section {
		background: white;
		padding: 1.5rem;
		border-radius: 12px;
		margin-bottom: 2rem;
		box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
	}

	.filters-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 1rem;
	}

	.filters-header h3 {
		margin: 0;
		color: #2d3748;
		font-size: 1.1rem;
	}

	.clear-filters-btn {
		background: none;
		border: none;
		color: #667eea;
		font-size: 0.9rem;
		cursor: pointer;
		font-weight: 500;
	}

	.clear-filters-btn:hover {
		text-decoration: underline;
	}

	.filters-grid {
		display: grid;
		grid-template-columns: repeat(2, 1fr);
		gap: 1rem;
	}

	.filter-group {
		display: flex;
		flex-direction: column;
	}

	.filter-group label {
		font-size: 0.9rem;
		font-weight: 500;
		color: #4a5568;
		margin-bottom: 0.5rem;
	}

	.filter-select {
		padding: 0.75rem;
		border: 2px solid #e2e8f0;
		border-radius: 8px;
		font-size: 0.9rem;
		background: white;
		cursor: pointer;
	}

	.filter-select:focus {
		outline: none;
		border-color: #667eea;
		box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
	}

	/* History Section */
	.history-section {
		background: white;
		border-radius: 12px;
		overflow: hidden;
		box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
	}

	.history-header {
		padding: 1.5rem;
		border-bottom: 1px solid #e2e8f0;
	}

	.history-header h3 {
		margin: 0;
		color: #2d3748;
		font-size: 1.1rem;
	}

	.loading-state, .empty-state {
		padding: 3rem 1.5rem;
		text-align: center;
	}

	.loading-spinner {
		width: 40px;
		height: 40px;
		border: 3px solid #e2e8f0;
		border-top: 3px solid #667eea;
		border-radius: 50%;
		animation: spin 1s linear infinite;
		margin: 0 auto 1rem;
	}

	@keyframes spin {
		0% { transform: rotate(0deg); }
		100% { transform: rotate(360deg); }
	}

	.empty-icon {
		font-size: 3rem;
		margin-bottom: 1rem;
	}

	.empty-state h4 {
		color: #2d3748;
		margin-bottom: 0.5rem;
	}

	.empty-state p {
		color: #718096;
		margin: 0;
	}

	.history-list {
		display: flex;
		flex-direction: column;
	}

	.history-item {
		display: flex;
		align-items: center;
		padding: 1rem 1.5rem;
		border: none;
		border-bottom: 1px solid #e2e8f0;
		background: white;
		cursor: pointer;
		transition: background-color 0.2s;
		text-align: left;
		width: 100%;
	}

	.history-item:hover {
		background: #f7fafc;
	}

	.history-item:last-child {
		border-bottom: none;
	}

	.exchange-icon {
		font-size: 1.5rem;
		margin-right: 1rem;
	}

	.exchange-info {
		flex: 1;
	}

	.exchange-header {
		display: flex;
		align-items: center;
		gap: 0.5rem;
		margin-bottom: 0.25rem;
	}

	.currency-badge {
		background: #667eea;
		color: white;
		padding: 0.25rem 0.5rem;
		border-radius: 4px;
		font-size: 0.8rem;
		font-weight: 600;
	}

	.amount {
		font-weight: 600;
		color: #2d3748;
	}

	.status-badge {
		color: white;
		padding: 0.25rem 0.5rem;
		border-radius: 4px;
		font-size: 0.75rem;
		font-weight: 600;
		text-transform: capitalize;
		margin-left: auto;
	}

	.exchange-details {
		display: flex;
		justify-content: space-between;
		align-items: center;
		font-size: 0.9rem;
		color: #718096;
		margin-bottom: 0.25rem;
	}

	.exchange-rating {
		display: flex;
		align-items: center;
	}

	.stars {
		display: flex;
		gap: 0.1rem;
	}

	.star {
		font-size: 0.8rem;
		filter: grayscale(100%);
		opacity: 0.3;
	}

	.star.filled {
		filter: none;
		opacity: 1;
	}

	.exchange-arrow {
		color: #cbd5e0;
		margin-left: 1rem;
	}
</style>