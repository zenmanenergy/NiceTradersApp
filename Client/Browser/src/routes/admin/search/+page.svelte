<script>
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';
	import AdminLayout from '../../admin/AdminLayout.svelte';
	import SearchView from '../../admin/SearchView.svelte';
	import { formatDate, formatCurrency } from '../../../lib/adminUtils.js';

	export let data;
	
	let searchTerm = data.searchTerm || '';
	let searchType = data.searchType || 'listings';
	
	async function handleSearch() {
		if (!searchTerm.trim()) return;
		goto(`/admin/search?q=${encodeURIComponent(searchTerm)}&type=${searchType}`);
	}
	
	async function handleKeydown(e) {
		if (e.key === 'Enter') {
			handleSearch();
		}
	}
</script>

<AdminLayout>
	<div class="search-container">
		<div class="search-header">
			<h2>Search</h2>
		</div>
		
		<div class="search-controls">
			<div class="search-tabs">
				<button 
					class="tab-btn {searchType === 'users' ? 'active' : ''}"
					on:click={() => { searchType = 'users'; handleSearch(); }}
				>
					👤 Users
				</button>
				<button 
					class="tab-btn {searchType === 'listings' ? 'active' : ''}"
					on:click={() => { searchType = 'listings'; handleSearch(); }}
				>
					💱 Listings
				</button>
				<button 
					class="tab-btn {searchType === 'transactions' ? 'active' : ''}"
					on:click={() => { searchType = 'transactions'; handleSearch(); }}
				>
					💰 Transactions
				</button>
			</div>
			
			<div class="search-input-group">
				<input 
					type="text"
					placeholder="Search..."
					bind:value={searchTerm}
					on:keydown={handleKeydown}
					class="search-input"
				/>
				<button on:click={handleSearch} class="search-btn">Search</button>
			</div>
		</div>
		
		{#if data.error}
			<div class="error">{data.error}</div>
		{/if}
		
		{#if data.results.length > 0}
			<div class="results">
				<h3>Results ({data.count})</h3>
				<div class="results-list">
					{#each data.results as result}
						{#if searchType === 'users'}
							<div class="result-card" on:click={() => goto(`/admin/user/${result.user_id}`)}>
								<div class="result-icon">👤</div>
								<div class="result-info">
									<h4>{result.FirstName} {result.LastName}</h4>
									<p>{result.Email}</p>
									<small>Joined: {formatDate(result.DateCreated)}</small>
								</div>
								<div class="result-arrow">→</div>
							</div>
						{:else if searchType === 'listings'}
							<div class="result-card" on:click={() => goto(`/admin/listing/${result.listing_id}`)}>
								<div class="result-icon">💱</div>
								<div class="result-info">
									<h4>{result.currency} → {result.accept_currency}</h4>
									<p>{formatCurrency(result.amount, result.currency)}</p>
									<small>{result.location}</small>
								</div>
								<div class="result-arrow">→</div>
							</div>
						{:else if searchType === 'transactions'}
							<div class="result-card" on:click={() => goto(`/admin/transaction/${result.payment_id}`)}>
								<div class="result-icon">💰</div>
								<div class="result-info">
									<h4>Payment: {formatCurrency(result.amount, result.currency)}</h4>
									<p>Method: {result.payment_method}</p>
									<small>{formatDate(result.created_at)}</small>
								</div>
								<div class="result-arrow">→</div>
							</div>
						{/if}
					{/each}
				</div>
			</div>
		{:else if searchTerm}
			<div class="no-results">No results found for "{searchTerm}"</div>
		{/if}
	</div>
</AdminLayout>

<style>
	.search-container {
		padding: 20px;
	}
	
	.search-header {
		margin-bottom: 20px;
	}
	
	.search-header h2 {
		margin: 0;
		color: #333;
	}
	
	.search-controls {
		display: flex;
		flex-direction: column;
		gap: 15px;
		margin-bottom: 30px;
	}
	
	.search-tabs {
		display: flex;
		gap: 10px;
	}
	
	.tab-btn {
		padding: 10px 20px;
		border: 2px solid #ddd;
		background: white;
		border-radius: 8px;
		cursor: pointer;
		font-weight: 500;
		transition: all 0.3s;
	}
	
	.tab-btn.active {
		background: #667eea;
		color: white;
		border-color: #667eea;
	}
	
	.search-input-group {
		display: flex;
		gap: 10px;
	}
	
	.search-input {
		flex: 1;
		padding: 12px 15px;
		border: 2px solid #ddd;
		border-radius: 8px;
		font-size: 14px;
	}
	
	.search-input:focus {
		outline: none;
		border-color: #667eea;
		box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
	}
	
	.search-btn {
		padding: 12px 30px;
		background: #667eea;
		color: white;
		border: none;
		border-radius: 8px;
		cursor: pointer;
		font-weight: 600;
		transition: background 0.3s;
	}
	
	.search-btn:hover {
		background: #5568d3;
	}
	
	.results {
		margin-top: 30px;
	}
	
	.results h3 {
		margin: 0 0 15px 0;
		color: #333;
	}
	
	.results-list {
		display: flex;
		flex-direction: column;
		gap: 10px;
	}
	
	.result-card {
		display: flex;
		align-items: center;
		padding: 15px;
		background: white;
		border: 1px solid #e0e0e0;
		border-radius: 8px;
		cursor: pointer;
		transition: all 0.3s;
	}
	
	.result-card:hover {
		border-color: #667eea;
		box-shadow: 0 2px 10px rgba(102, 126, 234, 0.1);
	}
	
	.result-icon {
		font-size: 24px;
		margin-right: 15px;
		min-width: 40px;
		text-align: center;
	}
	
	.result-info {
		flex: 1;
	}
	
	.result-info h4 {
		margin: 0 0 5px 0;
		color: #333;
		font-size: 16px;
	}
	
	.result-info p {
		margin: 0 0 5px 0;
		color: #666;
		font-size: 14px;
	}
	
	.result-info small {
		color: #999;
		font-size: 12px;
	}
	
	.result-arrow {
		color: #667eea;
		font-size: 20px;
		margin-left: 10px;
	}
	
	.no-results {
		padding: 40px 20px;
		text-align: center;
		color: #999;
		font-style: italic;
	}
	
	.error {
		padding: 15px;
		background: #ffebee;
		color: #d32f2f;
		border-radius: 8px;
		margin-bottom: 20px;
	}
</style>
