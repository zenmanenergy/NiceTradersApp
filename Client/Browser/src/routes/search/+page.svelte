<script>
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';
	import { Session } from '../../Session.js';
	import { 
		handleSearchListings, 
		handleGetSearchFilters, 
		handleGetPopularSearches,
		handleQuickSearch,
		handleCurrencyPairSearch 
	} from './handleSearch.js';
	
	// Will be populated from API
	let availableCurrencies = [];
	let availableLocations = [];
	let popularSearches = null;
	
	// State variables
	let isLoading = false;
	let loadingFilters = true;
	let searchResults = [];
	let searchError = null;
	let pagination = {
		total: 0,
		limit: 20,
		offset: 0,
		hasMore: false
	};
	
	// Search filters
	let searchFilters = {
		currency: '',
		amountMin: '',
		amountMax: '',
		rateType: 'any',
		meetingPreference: 'any',
		verifiedOnly: false
	};
	
	let showFilters = false;
	let isSearching = false;
	let hasSearched = false;
	let currencySearchQuery = '';
	let showCurrencyDropdown = false;
	
	// Filtered currencies based on search query
	$: filteredCurrencyOptions = availableCurrencies.filter(currency => {
		if (!currencySearchQuery) return true;
		const query = currencySearchQuery.toLowerCase();
		return currency.toLowerCase().includes(query);
	});
	

	
	function goBack() {
		goto('/dashboard');
	}
	
	function toggleFilters() {
		showFilters = !showFilters;
	}
	
	function clearFilters() {
		searchFilters = {
			currency: '',
			amountMin: '',
			amountMax: '',
			rateType: 'any',
			meetingPreference: 'any',
			verifiedOnly: false
		};
		if (hasSearched) {
			performSearch();
		}
	}
	
	async function performSearch(resetPagination = true) {
		isSearching = true;
		hasSearched = true;
		searchError = null;
		
		if (resetPagination) {
			pagination.offset = 0;
		}
		
		const filters = {
			currency: searchFilters.currency || undefined,
			minAmount: searchFilters.amountMin || undefined,
			maxAmount: searchFilters.amountMax || undefined,
			sessionId: Session.SessionId,
			limit: pagination.limit,
			offset: pagination.offset
		};
		
		await handleSearchListings(filters, (response) => {
			isSearching = false;
			
			if (response && response.success) {
				if (resetPagination) {
					searchResults = response.listings || [];
				} else {
					// Append results for pagination
					searchResults = [...searchResults, ...(response.listings || [])];
				}
				pagination = response.pagination || pagination;
			} else {
				searchError = response?.error || 'Failed to search listings';
				searchResults = [];
			}
		});
	}
	
	function selectCurrency(currency) {
		searchFilters.currency = currency;
		currencySearchQuery = '';
		showCurrencyDropdown = false;
		performSearch();
	}
	
	function clearCurrencySelection() {
		searchFilters.currency = '';
		currencySearchQuery = '';
		performSearch();
	}
	
	function contactTrader(listing) {
		// In real app, would pass listing ID as route parameter
		goto('/contact');
	}
	
	function viewProfile(listing) {
		alert(`View ${listing.user.name}'s profile\n\nRating: ${listing.user.rating}/5\nCompleted trades: ${listing.user.trades}\n\n(This is just a prototype)`);
	}
	
	// Handle click outside to close dropdown
	function handleClickOutside(event) {
		if (!event.target.closest('.currency-search-container')) {
			showCurrencyDropdown = false;
		}
	}
	
	// Initialize data on mount
	onMount(async () => {
		await Session.handleSession();
		Session.GetSessionId(); // This sets Session.SessionId
		const sessionId = Session.SessionId;
		
		if (!sessionId) {
			goto('/login');
			return;
		}
		
		try {
			// Load search filters and popular searches
			await Promise.all([
				loadSearchFilters(),
				loadPopularSearches(),
				performInitialSearch()
			]);
			
		} catch (error) {
			console.error('[Search] Error initializing:', error);
			searchError = 'Failed to load search data';
		}
		
		// Add click outside listener
		document.addEventListener('click', handleClickOutside);
		
		return () => {
			document.removeEventListener('click', handleClickOutside);
		};
	});
	
	async function loadSearchFilters() {
		loadingFilters = true;
		await handleGetSearchFilters((response) => {
			loadingFilters = false;
			
			if (response && response.success) {
				availableCurrencies = response.currencies || [];
				availableLocations = response.locations || [];
			} else {
				console.error('[Search] Error loading filters:', response?.error);
			}
		});
	}
	
	async function loadPopularSearches() {
		await handleGetPopularSearches((response) => {
			if (response && response.success) {
				popularSearches = {
					popularPairs: response.popularPairs || [],
					popularLocations: response.popularLocations || [],
					trendingCurrencies: response.trendingCurrencies || []
				};
			} else {
				console.error('[Search] Error loading popular searches:', response?.error);
			}
		});
	}
	
	async function performInitialSearch() {
		// Show some initial results
		await performSearch();
	}
	
	async function loadMore() {
		if (!pagination.hasMore || isSearching) return;
		
		pagination.offset += pagination.limit;
		await performSearch(false);
	}
</script>

<svelte:head>
	<title>Search Currency - NICE Traders</title>
	<meta name="description" content="Search for currency exchange opportunities near you" />
</svelte:head>

<main class="search-container">
	<div class="header">
		<button class="back-button" on:click={goBack} aria-label="Go back">
			<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
				<polyline points="15,18 9,12 15,6"></polyline>
			</svg>
		</button>
		<h1 class="page-title">Search Currency</h1>
		<button class="filter-button" on:click={toggleFilters} aria-label="Toggle filters">
			<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
				<line x1="4" y1="21" x2="4" y2="14"></line>
				<line x1="4" y1="10" x2="4" y2="3"></line>
				<line x1="12" y1="21" x2="12" y2="12"></line>
				<line x1="12" y1="8" x2="12" y2="3"></line>
				<line x1="20" y1="21" x2="20" y2="16"></line>
				<line x1="20" y1="12" x2="20" y2="3"></line>
				<line x1="1" y1="14" x2="7" y2="14"></line>
				<line x1="9" y1="8" x2="15" y2="8"></line>
				<line x1="17" y1="16" x2="23" y2="16"></line>
			</svg>
		</button>
	</div>

	<!-- Quick Search -->
	<div class="quick-search">
		<h2 class="section-title">Search Currency</h2>
		<div class="currency-search-container">
			<div class="search-input-wrapper">
				<input 
					type="text" 
					bind:value={currencySearchQuery}
					placeholder="Search currencies..."
					class="currency-search-input"
					on:focus={() => showCurrencyDropdown = true}
				/>
				<div class="search-icon">🔍</div>
			</div>
			
			{#if showCurrencyDropdown && !loadingFilters}
				<div class="currency-dropdown">
					{#each filteredCurrencyOptions as currency}
						<button 
							class="currency-option"
							class:selected={searchFilters.currency === currency}
							on:click={() => selectCurrency(currency)}
						>
							<div class="option-info">
								<span class="option-code">{currency}</span>
							</div>
						</button>
					{/each}
					
					{#if filteredCurrencyOptions.length === 0}
						<div class="no-currencies">
							No currencies found
						</div>
					{/if}
				</div>
			{/if}
		</div>
		
		{#if searchFilters.currency}
			<div class="selected-currency-display">
				<div class="selected-currency-info">
					<img src={getFlagImage(searchFilters.currency)} alt="{searchFilters.currency} flag" class="selected-flag" />
					<span class="selected-text">Searching for {searchFilters.currency}</span>
				</div>
				<button class="clear-currency-button" on:click={clearCurrencySelection} aria-label="Clear currency selection">
					<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
						<line x1="18" y1="6" x2="6" y2="18"></line>
						<line x1="6" y1="6" x2="18" y2="18"></line>
					</svg>
				</button>
			</div>
		{/if}
	</div>

	<!-- Advanced Filters -->
	{#if showFilters}
		<div class="filters-panel">
			<div class="filters-header">
				<h3 class="filters-title">Search Filters</h3>
				<button class="clear-filters-button" on:click={clearFilters}>
					Clear All
				</button>
			</div>

			<div class="filters-grid">
				<!-- Currency Selection -->
				<div class="filter-group">
					<label for="currency-select" class="filter-label">Currency</label>
					<select 
						id="currency-select"
						bind:value={searchFilters.currency}
						class="filter-select"
						disabled={loadingFilters}
					>
						<option value="">Any Currency</option>
						{#each availableCurrencies as currency}
							<option value={currency}>{currency}</option>
						{/each}
					</select>
				</div>



				<!-- Amount Range -->
				<div class="filter-group">
					<label class="filter-label">Amount Range</label>
					<div class="amount-range">
						<input 
							type="number" 
							bind:value={searchFilters.amountMin}
							class="filter-input amount-input"
							placeholder="Min"
							min="1"
						/>
						<span class="range-separator">to</span>
						<input 
							type="number" 
							bind:value={searchFilters.amountMax}
							class="filter-input amount-input"
							placeholder="Max"
							min="1"
						/>
					</div>
				</div>

				<!-- Rate Type -->
				<div class="filter-group">
					<label for="rate-select" class="filter-label">Rate Type</label>
					<select 
						id="rate-select"
						bind:value={searchFilters.rateType}
						class="filter-select"
					>
						<option value="any">Any Rate</option>
						<option value="market">Market Rate</option>
						<option value="custom">Custom Rate</option>
					</select>
				</div>

				<!-- Meeting Preference -->
				<div class="filter-group">
					<label for="meeting-select" class="filter-label">Meeting Type</label>
					<select 
						id="meeting-select"
						bind:value={searchFilters.meetingPreference}
						class="filter-select"
					>
						<option value="any">Any Location</option>
						<option value="public">Public Places Only</option>
						<option value="flexible">Flexible Locations</option>
					</select>
				</div>

				<!-- Verified Only -->
				<div class="filter-group checkbox-group">
					<label class="checkbox-label">
						<input 
							type="checkbox" 
							bind:checked={searchFilters.verifiedOnly}
							class="filter-checkbox"
						/>
						<span class="checkbox-text">Verified traders only</span>
					</label>
				</div>
			</div>

			<div class="filters-actions">
				<button class="apply-filters-button" on:click={performSearch}>
					Apply Filters
				</button>
			</div>
		</div>
	{/if}

	<!-- Search Results -->
	<div class="results-section">
		<div class="results-header">
			<h2 class="section-title">
				{#if isSearching}
					Searching...
				{:else if hasSearched}
					{searchResults.length} Results Found
				{:else}
					Recent Listings
				{/if}
			</h2>
			
			{#if hasSearched && !isSearching}
				<button class="refresh-button" on:click={performSearch} aria-label="Refresh search">
					<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
						<polyline points="23,4 23,10 17,10"></polyline>
						<polyline points="1,20 1,14 7,14"></polyline>
						<path d="M20.49,9A9,9,0,0,0,5.64,5.64L1,10m22,4L18.36,18.36A9,9,0,0,1,3.51,15"></path>
					</svg>
				</button>
			{/if}
		</div>

		{#if isSearching}
			<div class="loading-container">
				<div class="loading-spinner"></div>
				<p class="loading-text">Searching for currency listings...</p>
			</div>
		{:else if searchError}
			<div class="error-container">
				<div class="error-icon">⚠️</div>
				<h3 class="error-title">Search Error</h3>
				<p class="error-text">{searchError}</p>
				<button class="retry-button" on:click={() => performSearch()}>
					Try Again
				</button>
			</div>
		{:else if searchResults.length === 0 && hasSearched}
			<div class="no-results">
				<div class="no-results-icon">🔍</div>
				<h3 class="no-results-title">No listings found</h3>
				<p class="no-results-text">Try adjusting your search filters or check back later for new listings.</p>
				<button class="clear-search-button" on:click={clearFilters}>
					Clear Filters
				</button>
			</div>
		{:else}
			<div class="listings-grid">
				{#each searchResults as listing (listing.listingId)}
					<div class="listing-card">
						<div class="listing-header">
							<div class="currency-info">
								<div class="currency-details">
									<span class="currency-amount">{listing.amount} {listing.currency}</span>
									<span class="currency-rate">Wants {listing.acceptCurrency}</span>
								</div>
							</div>
							<div class="listing-status">{listing.status}</div>
						</div>

						<div class="trader-info">
							<div class="trader-details">
								<div class="trader-name">
									{listing.user.firstName} {listing.user.lastName}
								</div>
								<div class="trader-stats">
									<div class="rating-info">
										<span class="rating-stars">⭐ {listing.user.rating || 'New'}</span>
										<span class="trades-count">({listing.user.trades || 0} trades)</span>
									</div>
								</div>
							</div>
							<button 
								class="profile-button"
								on:click={() => viewProfile(listing)}
								aria-label="View trader profile"
							>
								👤
							</button>
						</div>

						<div class="listing-details">
							<div class="detail-item">
								<span class="detail-label">Meeting:</span>
								<span class="detail-value">
									{listing.meetingPreference === 'public' ? 'Public places' : 
									 listing.meetingPreference === 'private' ? 'Private' : 'Flexible'}
								</span>
							</div>
							<div class="detail-item">
								<span class="detail-label">Available until:</span>
								<span class="detail-value">
									{listing.availableUntil ? new Date(listing.availableUntil).toLocaleDateString() : 'Not specified'}
								</span>
							</div>
						</div>

						<div class="listing-footer">
							<span class="posted-time">
								{listing.createdAt ? new Date(listing.createdAt).toLocaleDateString() : ''}
							</span>
							<button 
								class="contact-button"
								on:click={() => contactTrader(listing)}
							>
								Contact Trader
							</button>
						</div>
					</div>
				{/each}
			</div>
			
			<!-- Load More Button -->
			{#if pagination.hasMore}
				<div class="pagination-container">
					<button 
						class="load-more-button"
						on:click={loadMore}
						disabled={isSearching}
					>
						{#if isSearching}
							Loading...
						{:else}
							Load More ({pagination.total - searchResults.length} remaining)
						{/if}
					</button>
				</div>
			{/if}
		{/if}
	</div>
</main>

<style>
	.search-container {
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

	.back-button, .filter-button {
		background: rgba(255, 255, 255, 0.2);
		border: none;
		color: white;
		cursor: pointer;
		padding: 0.5rem;
		border-radius: 8px;
		transition: background-color 0.2s;
	}

	.back-button:hover, .filter-button:hover {
		background: rgba(255, 255, 255, 0.3);
	}

	.page-title {
		font-size: 1.25rem;
		font-weight: 600;
		margin: 0;
	}

	.quick-search {
		background: white;
		padding: 1.5rem;
		border-bottom: 1px solid #e2e8f0;
	}

	.section-title {
		font-size: 1.1rem;
		font-weight: 600;
		color: #2d3748;
		margin: 0 0 1rem;
	}

	.currency-search-container {
		position: relative;
	}

	.search-input-wrapper {
		position: relative;
	}

	.currency-search-input {
		width: 100%;
		padding: 0.875rem 1rem 0.875rem 3rem;
		border: 2px solid #e2e8f0;
		border-radius: 12px;
		font-size: 1rem;
		background: white;
		transition: border-color 0.2s;
		box-sizing: border-box;
	}

	.currency-search-input:focus {
		outline: none;
		border-color: #667eea;
	}

	.search-icon {
		position: absolute;
		left: 1rem;
		top: 50%;
		transform: translateY(-50%);
		color: #a0aec0;
		pointer-events: none;
	}

	.currency-dropdown {
		position: absolute;
		top: 100%;
		left: 0;
		right: 0;
		background: white;
		border: 2px solid #e2e8f0;
		border-top: none;
		border-radius: 0 0 12px 12px;
		max-height: 300px;
		overflow-y: auto;
		z-index: 20;
		box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
	}

	.currency-option {
		width: 100%;
		padding: 1rem;
		border: none;
		background: white;
		cursor: pointer;
		display: flex;
		align-items: center;
		gap: 0.75rem;
		transition: background-color 0.2s;
		text-align: left;
	}

	.currency-option:hover {
		background: #f7fafc;
	}

	.currency-option.selected {
		background: #edf2f7;
		color: #667eea;
	}

	.option-flag {
		width: 24px;
		height: 18px;
		object-fit: cover;
		border-radius: 2px;
		border: 1px solid #e2e8f0;
	}

	.option-info {
		display: flex;
		flex-direction: column;
	}

	.option-code {
		font-weight: 600;
		color: #2d3748;
		font-size: 0.95rem;
	}

	.option-name {
		color: #718096;
		font-size: 0.85rem;
	}

	.no-currencies {
		padding: 1rem;
		text-align: center;
		color: #a0aec0;
		font-size: 0.9rem;
	}

	.selected-currency-display {
		margin-top: 1rem;
		padding: 1rem;
		background: #edf2f7;
		border: 2px solid #667eea;
		border-radius: 12px;
		display: flex;
		justify-content: space-between;
		align-items: center;
	}

	.selected-currency-info {
		display: flex;
		align-items: center;
		gap: 0.75rem;
	}

	.selected-flag {
		width: 24px;
		height: 18px;
		object-fit: cover;
		border-radius: 2px;
		border: 1px solid #e2e8f0;
	}

	.selected-text {
		font-weight: 500;
		color: #667eea;
	}

	.clear-currency-button {
		background: rgba(102, 126, 234, 0.1);
		border: none;
		color: #667eea;
		cursor: pointer;
		padding: 0.5rem;
		border-radius: 6px;
		transition: background-color 0.2s;
	}

	.clear-currency-button:hover {
		background: rgba(102, 126, 234, 0.2);
	}

	/* Filters Panel */
	.filters-panel {
		background: white;
		border-bottom: 1px solid #e2e8f0;
		padding: 1.5rem;
		animation: slideDown 0.3s ease;
	}

	@keyframes slideDown {
		from {
			opacity: 0;
			transform: translateY(-10px);
		}
		to {
			opacity: 1;
			transform: translateY(0);
		}
	}

	.filters-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 1.5rem;
	}

	.filters-title {
		font-size: 1.1rem;
		font-weight: 600;
		color: #2d3748;
		margin: 0;
	}

	.clear-filters-button {
		background: none;
		border: none;
		color: #667eea;
		cursor: pointer;
		font-weight: 500;
		text-decoration: underline;
	}

	.filters-grid {
		display: grid;
		gap: 1.25rem;
		grid-template-columns: 1fr;
	}

	.filter-group {
		display: flex;
		flex-direction: column;
		gap: 0.5rem;
	}

	.filter-label {
		font-size: 0.9rem;
		font-weight: 500;
		color: #4a5568;
	}

	.filter-input, .filter-select {
		padding: 0.75rem;
		border: 2px solid #e2e8f0;
		border-radius: 8px;
		font-size: 1rem;
		background: white;
		transition: border-color 0.2s;
	}

	.filter-input:focus, .filter-select:focus {
		outline: none;
		border-color: #667eea;
	}

	.filter-range {
		width: 100%;
		height: 6px;
		border-radius: 3px;
		background: #e2e8f0;
		outline: none;
		appearance: none;
	}

	.filter-range::-webkit-slider-thumb {
		appearance: none;
		width: 20px;
		height: 20px;
		border-radius: 50%;
		background: #667eea;
		cursor: pointer;
		border: 2px solid white;
		box-shadow: 0 2px 4px rgba(0,0,0,0.2);
	}

	.amount-range {
		display: flex;
		align-items: center;
		gap: 0.75rem;
	}

	.amount-input {
		flex: 1;
	}

	.range-separator {
		color: #718096;
		font-size: 0.9rem;
	}

	.checkbox-group {
		padding: 1rem;
		background: #f7fafc;
		border-radius: 8px;
	}

	.checkbox-label {
		display: flex;
		align-items: center;
		cursor: pointer;
		gap: 0.75rem;
	}

	.filter-checkbox {
		accent-color: #667eea;
	}

	.checkbox-text {
		font-size: 0.95rem;
		color: #4a5568;
	}

	.filters-actions {
		margin-top: 1.5rem;
	}

	.apply-filters-button {
		width: 100%;
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		color: white;
		border: none;
		padding: 1rem;
		border-radius: 12px;
		font-size: 1rem;
		font-weight: 600;
		cursor: pointer;
		transition: transform 0.2s;
	}

	.apply-filters-button:hover {
		transform: translateY(-1px);
	}

	/* Results Section */
	.results-section {
		flex: 1;
		padding: 1.5rem;
	}

	.results-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 1.5rem;
	}

	.refresh-button {
		background: rgba(102, 126, 234, 0.1);
		border: none;
		color: #667eea;
		cursor: pointer;
		padding: 0.5rem;
		border-radius: 8px;
		transition: background-color 0.2s;
	}

	.refresh-button:hover {
		background: rgba(102, 126, 234, 0.2);
	}

	.loading-container {
		text-align: center;
		padding: 3rem 1rem;
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
		from { transform: rotate(0deg); }
		to { transform: rotate(360deg); }
	}

	.loading-text {
		color: #718096;
		font-size: 1rem;
	}

	.no-results {
		text-align: center;
		padding: 3rem 1rem;
	}

	.no-results-icon {
		font-size: 3rem;
		margin-bottom: 1rem;
	}

	.no-results-title {
		font-size: 1.25rem;
		font-weight: 600;
		color: #2d3748;
		margin: 0 0 0.5rem;
	}

	.no-results-text {
		color: #718096;
		margin: 0 0 1.5rem;
		line-height: 1.5;
	}

	.clear-search-button {
		background: #667eea;
		color: white;
		border: none;
		padding: 0.75rem 1.5rem;
		border-radius: 8px;
		font-weight: 500;
		cursor: pointer;
		transition: background-color 0.2s;
	}

	.clear-search-button:hover {
		background: #5a67d8;
	}

	/* Listings Grid */
	.listings-grid {
		display: grid;
		gap: 1.5rem;
		grid-template-columns: 1fr;
	}

	.listing-card {
		background: white;
		border: 1px solid #e2e8f0;
		border-radius: 12px;
		padding: 1.5rem;
		transition: box-shadow 0.2s, transform 0.2s;
	}

	.listing-card:hover {
		box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
		transform: translateY(-2px);
	}

	.listing-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 1rem;
	}

	.currency-info {
		display: flex;
		align-items: center;
		gap: 0.75rem;
	}

	.listing-flag {
		width: 28px;
		height: 21px;
		object-fit: cover;
		border-radius: 3px;
		border: 1px solid #e2e8f0;
	}

	.currency-amount {
		font-size: 1.25rem;
		font-weight: 600;
		color: #2d3748;
		display: block;
	}

	.currency-rate {
		font-size: 0.9rem;
		color: #667eea;
		font-weight: 500;
	}

	.listing-distance {
		font-size: 0.85rem;
		color: #718096;
		background: #f7fafc;
		padding: 0.25rem 0.5rem;
		border-radius: 6px;
	}

	.trader-info {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 1rem;
		padding-bottom: 1rem;
		border-bottom: 1px solid #f1f5f9;
	}

	.trader-name {
		font-weight: 600;
		color: #2d3748;
		display: flex;
		align-items: center;
		gap: 0.5rem;
		margin-bottom: 0.25rem;
	}

	.verified-badge {
		background: #48bb78;
		color: white;
		border-radius: 50%;
		width: 18px;
		height: 18px;
		display: flex;
		align-items: center;
		justify-content: center;
		font-size: 12px;
		font-weight: bold;
	}

	.trader-stats {
		display: flex;
		gap: 1rem;
		font-size: 0.85rem;
		color: #718096;
	}

	.profile-button {
		background: #f7fafc;
		border: 1px solid #e2e8f0;
		border-radius: 8px;
		padding: 0.5rem;
		cursor: pointer;
		font-size: 1rem;
		transition: background-color 0.2s;
	}

	.profile-button:hover {
		background: #edf2f7;
	}

	.listing-details {
		display: grid;
		gap: 0.5rem;
		margin-bottom: 1rem;
	}

	.detail-item {
		display: flex;
		justify-content: space-between;
		font-size: 0.9rem;
	}

	.detail-label {
		color: #718096;
		font-weight: 500;
	}

	.detail-value {
		color: #4a5568;
	}

	.listing-notes {
		background: #f7fafc;
		border-radius: 8px;
		padding: 1rem;
		margin-bottom: 1rem;
	}

	.notes-text {
		font-size: 0.9rem;
		color: #4a5568;
		line-height: 1.5;
		margin: 0;
	}

	.listing-footer {
		display: flex;
		justify-content: space-between;
		align-items: center;
	}

	.posted-time {
		font-size: 0.85rem;
		color: #a0aec0;
	}

	.contact-button {
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		color: white;
		border: none;
		padding: 0.75rem 1.5rem;
		border-radius: 8px;
		font-weight: 600;
		cursor: pointer;
		font-size: 0.9rem;
		transition: transform 0.2s;
	}

	.contact-button:hover {
		transform: translateY(-1px);
	}

	/* Responsive adjustments */
	@media (max-width: 375px) {
		.search-container {
			max-width: 375px;
		}
		
		.quick-search, .filters-panel, .results-section {
			padding: 1rem;
		}
		
		.currency-search-input {
			padding: 0.75rem 1rem 0.75rem 2.5rem;
		}
		
		.listing-card {
			padding: 1rem;
		}
	}

	@media (max-width: 320px) {
		.search-container {
			max-width: 320px;
		}
		
		.header {
			padding: 1rem;
		}
		
		.currency-dropdown {
			max-height: 250px;
		}
		
		.trader-stats {
			gap: 0.5rem;
		}
		
		.listing-footer {
			flex-direction: column;
			gap: 0.75rem;
			align-items: stretch;
		}
		
		.contact-button {
			width: 100%;
		}
	}

	/* Error Styles */
	.error-container {
		text-align: center;
		padding: 3rem 1.5rem;
		background: white;
		margin: 1rem;
		border-radius: 12px;
		box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
	}

	.error-icon {
		font-size: 3rem;
		margin-bottom: 1rem;
	}

	.error-title {
		font-size: 1.25rem;
		font-weight: 600;
		color: #e53e3e;
		margin-bottom: 1rem;
	}

	.error-text {
		color: #718096;
		margin-bottom: 2rem;
		line-height: 1.5;
	}

	.retry-button {
		background: #e53e3e;
		color: white;
		border: none;
		padding: 0.75rem 1.5rem;
		border-radius: 8px;
		font-weight: 600;
		cursor: pointer;
		transition: background-color 0.2s;
	}

	.retry-button:hover {
		background: #c53030;
	}

	/* Pagination Styles */
	.pagination-container {
		padding: 1rem;
		text-align: center;
	}

	.load-more-button {
		background: #4a5568;
		color: white;
		border: none;
		padding: 0.75rem 1.5rem;
		border-radius: 8px;
		font-weight: 600;
		cursor: pointer;
		transition: background-color 0.2s;
	}

	.load-more-button:hover:not(:disabled) {
		background: #2d3748;
	}

	.load-more-button:disabled {
		opacity: 0.6;
		cursor: not-allowed;
	}

	/* Status Styles */
	.listing-status {
		font-size: 0.85rem;
		color: #48bb78;
		font-weight: 600;
		text-transform: capitalize;
	}

	/* .user-email class removed - no longer displaying email in search results */
	
	.rating-info {
		display: flex;
		align-items: center;
		gap: 0.5rem;
		font-size: 0.85rem;
	}

	.rating-stars {
		color: #f6ad55;
		font-weight: 600;
	}

	.trades-count {
		color: #718096;
		font-size: 0.8rem;
	}
</style>