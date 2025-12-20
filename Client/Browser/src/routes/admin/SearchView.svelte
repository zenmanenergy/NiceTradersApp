<script>
	import { goto } from '$app/navigation';
	import SuperFetch from '../../SuperFetch.js';
	import { searchState, viewState, userDetailState } from '../../lib/adminStore.js';
	import { formatDate, formatCurrency } from '../../lib/adminUtils.js';
	
	export let viewUser;
	export let viewListing = async (listingId) => {
		goto(`/admin/listing/${listingId}`);
	};
	export let viewTransaction;
	
	async function search() {
		if (!$searchState.searchTerm.trim()) return;
		
		searchState.update(state => ({ ...state, loading: true, error: null, searchResults: [] }));
		
		try {
			let endpoint = '';
			let params = { search: $searchState.searchTerm };
			
			switch($searchState.searchType) {
				case 'users':
					endpoint = '/Admin/SearchUsers';
					break;
				case 'listings':
					endpoint = '/Admin/SearchListings';
					break;
				case 'transactions':
					endpoint = '/Admin/SearchTransactions';
					break;
				case 'email':
					endpoint = '/Admin/SearchUsers';
					params.email = $searchState.searchTerm;
					break;
			}
			
			const response = await SuperFetch(endpoint, params);
			
			searchState.update(state => ({
				...state,
				searchResults: response.success ? (response.data || []) : [],
				error: response.success ? null : (response.error || 'Search failed'),
				loading: false
			}));
		} catch (err) {
			searchState.update(state => ({ ...state, error: err.message, loading: false }));
		}
	}
	
	function setSearchType(type) {
		searchState.update(state => ({ ...state, searchType: type }));
	}
	
	function updateSearchTerm(value) {
		searchState.update(state => ({ ...state, searchTerm: value }));
	}
	
	function handleKeyDown(e) {
		if (e.key === 'Enter') search();
	}
</script>

<div class="search-container">
	<div class="search-type-selector">
		<button 
			class="type-btn {$searchState.searchType === 'users' ? 'active' : ''}" 
			on:click={() => setSearchType('users')}
		>
			👤 Users
		</button>
		<button 
			class="type-btn {$searchState.searchType === 'email' ? 'active' : ''}" 
			on:click={() => setSearchType('email')}
		>
			📧 Email
		</button>
		<button 
			class="type-btn {$searchState.searchType === 'listings' ? 'active' : ''}" 
			on:click={() => setSearchType('listings')}
		>
			💱 Listings
		</button>
		<button 
			class="type-btn {$searchState.searchType === 'transactions' ? 'active' : ''}" 
			on:click={() => setSearchType('transactions')}
		>
			💰 Transactions
		</button>
	</div>
	
	<div class="search-box">
		<input 
			type="text" 
			placeholder="Search {$searchState.searchType}..." 
			value={$searchState.searchTerm}
			on:input={(e) => updateSearchTerm(e.target.value)}
			on:keydown={handleKeyDown}
			class="search-input"
		/>
		<button class="search-btn" on:click={search}>Search</button>
	</div>

	{#if $searchState.loading}
		<div class="loading">Searching...</div>
	{:else if $searchState.error}
		<div class="error">Error: {$searchState.error}</div>
	{:else if $searchState.searchResults.length > 0}
		<div class="results-container">
			<h3>Results ({$searchState.searchResults.length})</h3>
			<div class="results-list">
				{#each $searchState.searchResults as result}
					{#if $searchState.searchType === 'users' || $searchState.searchType === 'email'}
						<div class="result-card" on:click={() => viewUser(result.user_id, `${result.FirstName} ${result.LastName}`)}>
							<div class="result-icon">👤</div>
							<div class="result-info">
								<h4>{result.FirstName} {result.LastName}</h4>
								<p>{result.Email}</p>
								<small>Joined: {formatDate(result.DateCreated)}</small>
							</div>
							<div class="result-arrow">→</div>
						</div>
					{:else if $searchState.searchType === 'listings'}
						<div class="result-card" on:click={() => viewListing(result.listing_id)}>
							<div class="result-icon">💱</div>
							<div class="result-info">
								<h4>{result.currency} → {result.accept_currency}</h4>
								<p>{formatCurrency(result.amount, result.currency)}</p>
								<small>{result.location}</small>
							</div>
							<div class="result-arrow">→</div>
						</div>
					{:else if $searchState.searchType === 'transactions'}
						<div class="result-card" on:click={() => viewTransaction(result.access_id, `Purchase ${result.access_id.substring(0, 8)}`)}>
							<div class="result-icon">💰</div>
							<div class="result-info">
								<h4>Purchase: {formatCurrency(result.amount_paid, result.currency)}</h4>
								<p>Payment: {result.payment_method}</p>
								<small>{formatDate(result.purchased_at)}</small>
							</div>
							<div class="result-arrow">→</div>
						</div>
					{/if}
				{/each}
			</div>
		</div>
	{/if}
</div>

<style>
	.search-container {
		background: white;
		padding: 30px;
		border-radius: 12px;
		box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
	}

	.search-type-selector {
		display: flex;
		gap: 10px;
		margin-bottom: 20px;
		flex-wrap: wrap;
	}

	.type-btn {
		padding: 12px 24px;
		border: 2px solid #e0e0e0;
		background: white;
		border-radius: 8px;
		cursor: pointer;
		font-weight: 500;
		transition: all 0.2s;
	}

	.type-btn:hover {
		border-color: #667eea;
		background: #f0f4ff;
	}

	.type-btn.active {
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		color: white;
		border-color: transparent;
	}

	.search-box {
		display: flex;
		gap: 10px;
		margin-bottom: 20px;
	}

	.search-input {
		flex: 1;
		padding: 14px 18px;
		border: 2px solid #e0e0e0;
		border-radius: 8px;
		font-size: 1rem;
		transition: border-color 0.2s;
	}

	.search-input:focus {
		outline: none;
		border-color: #667eea;
	}

	.search-btn {
		padding: 14px 32px;
		border: none;
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		color: white;
		border-radius: 8px;
		cursor: pointer;
		font-weight: 600;
		font-size: 1rem;
		transition: all 0.2s;
	}

	.search-btn:hover {
		transform: translateY(-2px);
		box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
	}

	.results-container {
		margin-top: 30px;
	}

	.results-container h3 {
		margin: 0 0 20px 0;
		color: #333;
	}

	.results-list {
		display: grid;
		gap: 12px;
	}

	.result-card {
		display: flex;
		align-items: center;
		gap: 15px;
		padding: 16px;
		background: #f8f9fa;
		border-radius: 10px;
		cursor: pointer;
		transition: all 0.2s;
		border: 2px solid transparent;
	}

	.result-card:hover {
		background: white;
		border-color: #667eea;
		transform: translateX(5px);
		box-shadow: 0 4px 12px rgba(102, 126, 234, 0.15);
	}

	.result-icon {
		font-size: 2rem;
		width: 50px;
		text-align: center;
	}

	.result-info {
		flex: 1;
	}

	.result-info h4 {
		margin: 0 0 5px 0;
		color: #333;
	}

	.result-info p {
		margin: 0 0 3px 0;
		color: #666;
		font-size: 0.9rem;
	}

	.result-info small {
		color: #999;
		font-size: 0.8rem;
	}

	.result-arrow {
		font-size: 1.5rem;
		color: #667eea;
	}

	.empty-state {
		text-align: center;
		padding: 40px;
		color: #999;
		font-style: italic;
	}

	.loading,
	.error {
		text-align: center;
		padding: 40px;
		font-size: 1.1rem;
	}

	.error {
		color: #f44336;
	}
</style>
