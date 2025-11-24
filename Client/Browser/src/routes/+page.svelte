<script>
	import { onMount } from 'svelte';
	import SuperFetch from '../SuperFetch.js';
	
	let view = 'search'; // 'search' | 'user' | 'listing' | 'transaction' | 'message'
	let searchType = 'users';
	let searchTerm = '';
	let searchResults = [];
	let loading = false;
	let error = null;
	
	// Current detail view data
	let currentUser = null;
	let userListings = [];
	let userPurchases = [];
	let userMessages = [];
	let userRatings = [];
	
	let currentListing = null;
	let listingPurchases = [];
	let listingMessages = [];
	let listingOwner = null;
	
	let currentTransaction = null;
	let transactionBuyer = null;
	let transactionSeller = null;
	let transactionListing = null;
	
	let breadcrumbs = [];
	
	async function search() {
		if (!searchTerm.trim()) return;
		
		loading = true;
		error = null;
		searchResults = [];
		
		try {
			let endpoint = '';
			let params = { search: searchTerm };
			
			switch(searchType) {
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
					params.email = searchTerm;
					break;
			}
			
			const response = await SuperFetch(endpoint, params);
			
			if (response.success) {
				searchResults = response.data || [];
			} else {
				error = response.error || 'Search failed';
			}
		} catch (err) {
			error = err.message;
		} finally {
			loading = false;
		}
	}
	
	async function viewUser(userId, userName = 'User') {
		loading = true;
		error = null;
		
		try {
			// Get user details
			const userResponse = await SuperFetch('/Admin/GetUserById', { userId });
			if (!userResponse.success) throw new Error('Failed to load user');
			currentUser = userResponse.user;
			
			// Get user's listings
			const listingsResponse = await SuperFetch('/Admin/GetUserListings', { userId });
			userListings = listingsResponse.success ? listingsResponse.listings : [];
			
			// Get user's purchases
			const purchasesResponse = await SuperFetch('/Admin/GetUserPurchases', { userId });
			userPurchases = purchasesResponse.success ? purchasesResponse.purchases : [];
			
			// Get user's messages
			const messagesResponse = await SuperFetch('/Admin/GetUserMessages', { userId });
			userMessages = messagesResponse.success ? messagesResponse.messages : [];
			
			// Get user's ratings
			const ratingsResponse = await SuperFetch('/Admin/GetUserRatings', { userId });
			userRatings = ratingsResponse.success ? ratingsResponse.ratings : [];
			
			view = 'user';
			breadcrumbs = [...breadcrumbs, { type: 'user', id: userId, label: userName }];
		} catch (err) {
			error = err.message;
		} finally {
			loading = false;
		}
	}
	
	async function viewListing(listingId, listingName = 'Listing') {
		loading = true;
		error = null;
		
		try {
			// Get listing details
			const listingResponse = await SuperFetch('/Admin/GetListingById', { listingId });
			if (!listingResponse.success) throw new Error('Failed to load listing');
			currentListing = listingResponse.listing;
			
			// Get listing owner
			const ownerResponse = await SuperFetch('/Admin/GetUserById', { userId: currentListing.user_id });
			listingOwner = ownerResponse.success ? ownerResponse.user : null;
			
			// Get who purchased this listing
			const purchasesResponse = await SuperFetch('/Admin/GetListingPurchases', { listingId });
			listingPurchases = purchasesResponse.success ? purchasesResponse.purchases : [];
			
			// Get messages for this listing
			const messagesResponse = await SuperFetch('/Admin/GetListingMessages', { listingId });
			listingMessages = messagesResponse.success ? messagesResponse.messages : [];
			
			view = 'listing';
			breadcrumbs = [...breadcrumbs, { type: 'listing', id: listingId, label: listingName }];
		} catch (err) {
			error = err.message;
		} finally {
			loading = false;
		}
	}
	
	async function viewTransaction(transactionId, transactionName = 'Transaction') {
		loading = true;
		error = null;
		
		try {
			// Get transaction details
			const txResponse = await SuperFetch('/Admin/GetTransactionById', { transactionId });
			if (!txResponse.success) throw new Error('Failed to load transaction');
			currentTransaction = txResponse.transaction;
			
			// Get buyer details
			const buyerResponse = await SuperFetch('/Admin/GetUserById', { userId: currentTransaction.user_id });
			transactionBuyer = buyerResponse.success ? buyerResponse.user : null;
			
			// Get seller details (listing owner)
			const listingResponse = await SuperFetch('/Admin/GetListingById', { listingId: currentTransaction.listing_id });
			if (listingResponse.success) {
				transactionListing = listingResponse.listing;
				const sellerResponse = await SuperFetch('/Admin/GetUserById', { userId: listingResponse.listing.user_id });
				transactionSeller = sellerResponse.success ? sellerResponse.user : null;
			}
			
			view = 'transaction';
			breadcrumbs = [...breadcrumbs, { type: 'transaction', id: transactionId, label: transactionName }];
		} catch (err) {
			error = err.message;
		} finally {
			loading = false;
		}
	}
	
	function goBack() {
		if (breadcrumbs.length > 0) {
			breadcrumbs.pop();
			if (breadcrumbs.length === 0) {
				view = 'search';
			} else {
				const last = breadcrumbs[breadcrumbs.length - 1];
				breadcrumbs.pop(); // Remove it so it doesn't duplicate
				
				if (last.type === 'user') viewUser(last.id, last.label);
				else if (last.type === 'listing') viewListing(last.id, last.label);
				else if (last.type === 'transaction') viewTransaction(last.id, last.label);
			}
		} else {
			view = 'search';
		}
	}
	
	function resetToSearch() {
		view = 'search';
		breadcrumbs = [];
		currentUser = null;
		currentListing = null;
		currentTransaction = null;
	}
	
	function formatDate(dateStr) {
		if (!dateStr) return '-';
		return new Date(dateStr).toLocaleString();
	}
	
	function formatCurrency(amount, currency = 'USD') {
		if (amount === null || amount === undefined) return '-';
		return `${currency} ${parseFloat(amount).toFixed(2)}`;
	}
</script>

<main class="admin-container">
	<div class="admin-header">
		<h1>🔧 Admin Dashboard</h1>
		<p>Nice Traders Admin</p>
	</div>
	
	{#if breadcrumbs.length > 0}
		<div class="breadcrumb-nav">
			<button class="breadcrumb-btn" on:click={resetToSearch}>🏠 Home</button>
			{#each breadcrumbs as crumb, i}
				<span class="breadcrumb-separator">›</span>
				<span class="breadcrumb-item">{crumb.label}</span>
			{/each}
			<button class="back-btn" on:click={goBack}>← Back</button>
		</div>
	{/if}

	{#if view === 'search'}
		<div class="search-container">
			<div class="search-type-selector">
				<button class="type-btn {searchType === 'users' ? 'active' : ''}" on:click={() => searchType = 'users'}>
					👤 Users
				</button>
				<button class="type-btn {searchType === 'email' ? 'active' : ''}" on:click={() => searchType = 'email'}>
					📧 Email
				</button>
				<button class="type-btn {searchType === 'listings' ? 'active' : ''}" on:click={() => searchType = 'listings'}>
					💱 Listings
				</button>
				<button class="type-btn {searchType === 'transactions' ? 'active' : ''}" on:click={() => searchType = 'transactions'}>
					💰 Transactions
				</button>
			</div>
			
			<div class="search-box">
				<input 
					type="text" 
					placeholder="Search {searchType}..." 
					bind:value={searchTerm}
					on:keydown={(e) => e.key === 'Enter' && search()}
					class="search-input"
				/>
				<button class="search-btn" on:click={search}>Search</button>
			</div>

			{#if loading}
				<div class="loading">Searching...</div>
			{:else if error}
				<div class="error">Error: {error}</div>
			{:else if searchResults.length > 0}
				<div class="results-container">
					<h3>Results ({searchResults.length})</h3>
					<div class="results-list">
						{#each searchResults as result}
							{#if searchType === 'users' || searchType === 'email'}
								<div class="result-card" on:click={() => viewUser(result.UserId, `${result.FirstName} ${result.LastName}`)}>
									<div class="result-icon">👤</div>
									<div class="result-info">
										<h4>{result.FirstName} {result.LastName}</h4>
										<p>{result.Email}</p>
										<small>Joined: {formatDate(result.DateCreated)}</small>
									</div>
									<div class="result-arrow">→</div>
								</div>
							{:else if searchType === 'listings'}
								<div class="result-card" on:click={() => viewListing(result.listing_id, `${result.currency} → ${result.accept_currency}`)}>
									<div class="result-icon">💱</div>
									<div class="result-info">
										<h4>{result.currency} → {result.accept_currency}</h4>
										<p>{formatCurrency(result.amount, result.currency)}</p>
										<small>{result.location}</small>
									</div>
									<div class="result-arrow">→</div>
								</div>
							{:else if searchType === 'transactions'}
								<div class="result-card" on:click={() => viewTransaction(result.access_id, `Transaction ${result.access_id.substring(0, 8)}`)}>
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
	
	{:else if view === 'user' && currentUser}
		<div class="detail-view">
			<div class="detail-header">
				<h2>👤 {currentUser.FirstName} {currentUser.LastName}</h2>
				<span class="badge {currentUser.IsActive ? 'active' : 'inactive'}">
					{currentUser.IsActive ? 'Active' : 'Inactive'}
				</span>
			</div>
			
			<div class="detail-grid">
				<div class="info-card">
					<h3>Contact Information</h3>
					<div class="info-row"><strong>Email:</strong> {currentUser.Email}</div>
					<div class="info-row"><strong>Phone:</strong> {currentUser.Phone || '-'}</div>
					<div class="info-row"><strong>Location:</strong> {currentUser.Location || '-'}</div>
					<div class="info-row"><strong>Bio:</strong> {currentUser.Bio || '-'}</div>
				</div>
				
				<div class="info-card">
					<h3>Statistics</h3>
					<div class="info-row"><strong>Rating:</strong> {currentUser.Rating} ⭐</div>
					<div class="info-row"><strong>Total Exchanges:</strong> {currentUser.TotalExchanges}</div>
					<div class="info-row"><strong>User Type:</strong> {currentUser.UserType}</div>
					<div class="info-row"><strong>Joined:</strong> {formatDate(currentUser.DateCreated)}</div>
				</div>
			</div>

			<div class="section">
				<h3>📋 Listings ({userListings.length})</h3>
				{#if userListings.length === 0}
					<p class="empty-state">No listings</p>
				{:else}
					<div class="list-grid">
						{#each userListings as listing}
							<div class="list-card" on:click={() => viewListing(listing.listing_id, `${listing.currency} → ${listing.accept_currency}`)}>
								<div class="list-header">
									<strong>{listing.currency} → {listing.accept_currency}</strong>
									<span class="status-badge {listing.status}">{listing.status}</span>
								</div>
								<div>{formatCurrency(listing.amount, listing.currency)}</div>
								<div class="list-footer">{listing.location}</div>
							</div>
						{/each}
					</div>
				{/if}
			</div>

			<div class="section">
				<h3>💰 Purchases ({userPurchases.length})</h3>
				{#if userPurchases.length === 0}
					<p class="empty-state">No purchases</p>
				{:else}
					<div class="list-grid">
						{#each userPurchases as purchase}
							<div class="list-card" on:click={() => viewTransaction(purchase.access_id, `Purchase ${purchase.access_id.substring(0, 8)}`)}>
								<div class="list-header">
									<strong>{formatCurrency(purchase.amount_paid, purchase.currency)}</strong>
									<span class="status-badge {purchase.status}">{purchase.status}</span>
								</div>
								<div>Payment: {purchase.payment_method}</div>
								<div class="list-footer">{formatDate(purchase.purchased_at)}</div>
							</div>
						{/each}
					</div>
				{/if}
			</div>

			<div class="section">
				<h3>💬 Messages ({userMessages.length})</h3>
				{#if userMessages.length === 0}
					<p class="empty-state">No messages</p>
				{:else}
					<div class="messages-list">
						{#each userMessages as message}
							<div class="message-card">
								<div class="message-header">
									<span>{message.message_type}</span>
									<span>{formatDate(message.sent_at)}</span>
								</div>
								<div class="message-text">{message.message_text || '-'}</div>
							</div>
						{/each}
					</div>
				{/if}
			</div>
		</div>

	{:else if view === 'listing' && currentListing}
		<div class="detail-view">
			<div class="detail-header">
				<h2>💱 {currentListing.currency} → {currentListing.accept_currency}</h2>
				<span class="badge {currentListing.status}">{currentListing.status}</span>
			</div>
			
			<div class="detail-grid">
				<div class="info-card">
					<h3>Listing Details</h3>
					<div class="info-row"><strong>Amount:</strong> {formatCurrency(currentListing.amount, currentListing.currency)}</div>
					<div class="info-row"><strong>Location:</strong> {currentListing.location}</div>
					<div class="info-row"><strong>Coordinates:</strong> {currentListing.latitude}, {currentListing.longitude}</div>
					<div class="info-row"><strong>Meeting Preference:</strong> {currentListing.meeting_preference}</div>
					<div class="info-row"><strong>Available Until:</strong> {formatDate(currentListing.available_until)}</div>
					<div class="info-row"><strong>Created:</strong> {formatDate(currentListing.created_at)}</div>
				</div>
				
				{#if listingOwner}
					<div class="info-card clickable" on:click={() => viewUser(listingOwner.UserId, `${listingOwner.FirstName} ${listingOwner.LastName}`)}>
						<h3>👤 Owner</h3>
						<div class="info-row"><strong>Name:</strong> {listingOwner.FirstName} {listingOwner.LastName}</div>
						<div class="info-row"><strong>Email:</strong> {listingOwner.Email}</div>
						<div class="info-row"><strong>Rating:</strong> {listingOwner.Rating} ⭐</div>
						<div class="click-hint">Click to view user →</div>
					</div>
				{/if}
			</div>

			<div class="section">
				<h3>💰 Purchases ({listingPurchases.length})</h3>
				{#if listingPurchases.length === 0}
					<p class="empty-state">No purchases yet</p>
				{:else}
					<div class="list-grid">
						{#each listingPurchases as purchase}
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
				<h3>💬 Messages ({listingMessages.length})</h3>
				{#if listingMessages.length === 0}
					<p class="empty-state">No messages</p>
				{:else}
					<div class="messages-list">
						{#each listingMessages as message}
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

	{:else if view === 'transaction' && currentTransaction}
		<div class="detail-view">
			<div class="detail-header">
				<h2>💰 Transaction Details</h2>
				<span class="badge {currentTransaction.status}">{currentTransaction.status}</span>
			</div>
			
			<div class="detail-grid">
				<div class="info-card">
					<h3>Payment Information</h3>
					<div class="info-row"><strong>Amount Paid:</strong> {formatCurrency(currentTransaction.amount_paid, currentTransaction.currency)}</div>
					<div class="info-row"><strong>Payment Method:</strong> {currentTransaction.payment_method}</div>
					<div class="info-row"><strong>Transaction ID:</strong> {currentTransaction.transaction_id || '-'}</div>
					<div class="info-row"><strong>Purchased:</strong> {formatDate(currentTransaction.purchased_at)}</div>
					<div class="info-row"><strong>Expires:</strong> {formatDate(currentTransaction.expires_at) || 'Never'}</div>
				</div>
				
				<div class="info-card">
					<h3>Exchange Rate Info</h3>
					<div class="info-row"><strong>From Currency:</strong> {currentTransaction.from_currency || '-'}</div>
					<div class="info-row"><strong>To Currency:</strong> {currentTransaction.to_currency || '-'}</div>
					<div class="info-row"><strong>Exchange Rate:</strong> {currentTransaction.exchange_rate || '-'}</div>
					<div class="info-row"><strong>Locked Amount:</strong> {currentTransaction.locked_amount ? formatCurrency(currentTransaction.locked_amount, currentTransaction.to_currency) : '-'}</div>
					<div class="info-row"><strong>Rate Date:</strong> {currentTransaction.rate_calculation_date || '-'}</div>
				</div>
			</div>

			<div class="section">
				<h3>👥 Parties Involved</h3>
				<div class="detail-grid">
					{#if transactionBuyer}
						<div class="info-card clickable" on:click={() => viewUser(transactionBuyer.UserId, `${transactionBuyer.FirstName} ${transactionBuyer.LastName}`)}>
							<h4>💳 Buyer</h4>
							<div class="info-row"><strong>Name:</strong> {transactionBuyer.FirstName} {transactionBuyer.LastName}</div>
							<div class="info-row"><strong>Email:</strong> {transactionBuyer.Email}</div>
							<div class="info-row"><strong>Rating:</strong> {transactionBuyer.Rating} ⭐</div>
							<div class="click-hint">Click to view user →</div>
						</div>
					{/if}

					{#if transactionSeller}
						<div class="info-card clickable" on:click={() => viewUser(transactionSeller.UserId, `${transactionSeller.FirstName} ${transactionSeller.LastName}`)}>
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
					<div class="info-card clickable" on:click={() => viewListing(transactionListing.listing_id, `${transactionListing.currency} → ${transactionListing.accept_currency}`)}>
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
</main>

<style>
	:global(body) {
		margin: 0;
		padding: 0;
		font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
		background: #f5f7fa;
	}

	.admin-container {
		max-width: 1400px;
		margin: 0 auto;
		padding: 20px;
	}

	.admin-header {
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		color: white;
		padding: 30px;
		border-radius: 12px;
		margin-bottom: 20px;
		box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
	}

	.admin-header h1 {
		margin: 0 0 10px 0;
		font-size: 2rem;
	}

	.admin-header p {
		margin: 0;
		opacity: 0.9;
	}

	.breadcrumb-nav {
		display: flex;
		align-items: center;
		gap: 10px;
		padding: 15px 20px;
		background: white;
		border-radius: 8px;
		margin-bottom: 20px;
		box-shadow: 0 2px 5px rgba(0,0,0,0.05);
		flex-wrap: wrap;
	}

	.breadcrumb-btn, .back-btn {
		padding: 8px 16px;
		border: none;
		background: #667eea;
		color: white;
		border-radius: 6px;
		cursor: pointer;
		font-weight: 500;
		transition: all 0.2s;
	}

	.breadcrumb-btn:hover, .back-btn:hover {
		background: #5568d3;
		transform: translateY(-1px);
	}

	.back-btn {
		margin-left: auto;
	}

	.breadcrumb-separator {
		color: #999;
		font-size: 1.2rem;
	}

	.breadcrumb-item {
		color: #333;
		font-weight: 500;
	}

	.search-container {
		background: white;
		padding: 30px;
		border-radius: 12px;
		box-shadow: 0 2px 10px rgba(0,0,0,0.05);
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

	.detail-view {
		background: white;
		padding: 30px;
		border-radius: 12px;
		box-shadow: 0 2px 10px rgba(0,0,0,0.05);
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

	.info-card h3, .info-card h4 {
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

	.loading, .error {
		text-align: center;
		padding: 40px;
		font-size: 1.1rem;
	}

	.error {
		color: #f44336;
	}

	@media (max-width: 768px) {
		.admin-container {
			padding: 10px;
		}

		.detail-grid {
			grid-template-columns: 1fr;
		}

		.list-grid {
			grid-template-columns: 1fr;
		}

		.breadcrumb-nav {
			font-size: 0.9rem;
		}
	}
</style>
