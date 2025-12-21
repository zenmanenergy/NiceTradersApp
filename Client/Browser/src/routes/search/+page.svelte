<script>
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';
	import { formatDate, formatCurrency } from '$lib/adminUtils.js';
	import AdminLayout from '$lib/AdminLayout.svelte';
	import { onMount } from 'svelte';

	let searchTerm = '';
	let searchType = 'listings';
	let results = [];
	let count = 0;
	let error = null;
	let loading = false;
	
	onMount(() => {
		// Get initial search params from URL
		const searchParams = new URLSearchParams(window.location.search);
		searchTerm = searchParams.get('q') || '';
		searchType = searchParams.get('type') || 'listings';
		
		// If we have a search term, perform the search
		if (searchTerm.trim()) {
			performSearch();
		}
	});
	
	async function performSearch() {
		if (!searchTerm.trim()) {
			results = [];
			count = 0;
			return;
		}
		
		loading = true;
		error = null;
		
		try {
			const API_URL = 'https://api.nicetraders.net';
			const endpoint = `${API_URL}/Admin/Search${searchType.charAt(0).toUpperCase() + searchType.slice(1)}?search=${encodeURIComponent(searchTerm)}`;
			console.log(`[Search] Calling endpoint: ${endpoint}`);
			
			const response = await fetch(endpoint, {
				method: 'GET',
				headers: {
					'Content-Type': 'application/json'
				}
			});
			
			const contentType = response.headers.get('content-type');
			console.log(`[Search] Response status: ${response.status}, content-type: ${contentType}`);
			
			if (!response.ok) {
				const text = await response.text();
				console.error(`[Search] API error ${response.status}:`, text.substring(0, 500));
				throw new Error(`API error: ${response.status}`);
			}
			
			const data = await response.json();
			console.log(`[Search] Got ${(data.data || []).length} results`);
			
			results = data.data || [];
			count = results.length;
		} catch (err) {
			console.error('[Search Error]:', err.message);
			error = err.message;
			results = [];
			count = 0;
		} finally {
			loading = false;
		}
	}
	
	async function handleSearch() {
		if (!searchTerm.trim()) return;
		goto(`/search?q=${encodeURIComponent(searchTerm)}&type=${searchType}`);
		await performSearch();
	}
	
	async function handleKeydown(e) {
		if (e.key === 'Enter') {
			handleSearch();
		}
	}
	
	function handleTabChange(newType) {
		searchType = newType;
		if (searchTerm.trim()) {
			goto(`/search?q=${encodeURIComponent(searchTerm)}&type=${newType}`);
			performSearch();
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
				<button on:click={handleSearch} class="search-btn" disabled={loading}>
					{loading ? 'Searching...' : 'Search'}
				</button>
			</div>
		</div>
		
		{#if error}
			<div class="error">{error}</div>
		{/if}
		
		{#if loading}
			<div class="loading">Searching...</div>
		{/if}
		
		{#if results.length > 0}
			<div class="results">
				<h3>Results ({count})</h3>
				<div class="results-list">
					{#each results as result}
						{#if searchType === 'users'}
							<div class="result-card" on:click={() => goto(`/user/${result.user_id}`)}>
								<div class="result-icon">👤</div>
								<div class="result-info">
									<h4>{result.FirstName} {result.LastName}</h4>
									<p>{result.Email}</p>
									<small>Joined: {formatDate(result.DateCreated)}</small>
								</div>
								<div class="result-arrow">→</div>
							</div>
						{:else if searchType === 'listings'}
							<div class="result-card" on:click={() => goto(`/listing/${result.listing_id}`)}>
								<div class="result-icon">💱</div>
								<div class="result-info">
									<h4>{result.currency} → {result.accept_currency}</h4>
									<p>{formatCurrency(result.amount, result.currency)}</p>
									<small>{result.location}</small>
								</div>
								<div class="result-arrow">→</div>
							</div>
						{:else if searchType === 'transactions'}
							<div class="result-card" on:click={() => goto(`/transaction/${result.payment_id}`)}>
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
	
	.search-btn:disabled {
		background: #999;
		cursor: not-allowed;
		opacity: 0.7;
	}
	
	.loading {
		padding: 20px;
		text-align: center;
		color: #667eea;
		font-weight: 600;
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
