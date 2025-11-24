<script>
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';
	import { Session } from '../../Session.js';
	import { 
		handleGetUserDashboard, 
		handleGetUserStatistics, 
		handleGetMyActiveListings,
		handleGetDashboardSummary,
		handleGetPurchasedContacts,
		handleGetListingPurchases,
		handleGetContactMessages,
		handleSendContactMessage
	} from './handleDashboard.js';
	
	// Real user data from API
	let user = {
		name: 'Loading...',
		rating: 0,
		totalExchanges: 0,
		joinDate: 'Loading...'
	};
	
	// Real dashboard data
	let dashboardData = null;
	let statisticsData = null;
	let isLoading = true;
	let error = null;
	
	// Real activity and listings data
	let myListings = [];
	
	// Contact and messaging data
	let purchasedContacts = [];
	let listingPurchases = [];
	let allActiveExchanges = [];
	let selectedConversation = null;
	let conversationMessages = [];
	let newMessage = '';
	let showMessaging = false;
	
	function updateAllActiveExchanges() {
		console.log('[Dashboard] Updating active exchanges');
		console.log('[Dashboard] purchasedContacts:', purchasedContacts);
		console.log('[Dashboard] listingPurchases:', listingPurchases);
		allActiveExchanges = [
			...purchasedContacts.map(contact => ({...contact, type: 'buyer'})),
			...listingPurchases.map(purchase => ({...purchase, type: 'seller'}))
		];
		console.log('[Dashboard] allActiveExchanges:', allActiveExchanges);
	}
	
	// Load dashboard data on component mount
	onMount(async () => {
		console.log('[Dashboard] onMount START');
		await Session.handleSession();
		console.log('[Dashboard] Session handled');
		Session.GetSessionId(); // This sets Session.SessionId
		const sessionId = Session.SessionId;
		console.log('[Dashboard] SessionId:', sessionId);
		
		if (!sessionId) {
			goto('/login');
			return;
		}
		
		isLoading = true;
		error = null;
		
		try {
			console.log('[Dashboard] Starting to load dashboard data...');
			console.log('[Dashboard] Session ID:', sessionId);
			
			// Load dashboard data
			handleGetDashboardSummary(sessionId, (response) => {
				if (response && response.success) {
					dashboardData = response.dashboard;
					statisticsData = response.statistics;
					
					// Update user info
					if (dashboardData && dashboardData.user) {
						user = {
							name: `${dashboardData.user.firstName} ${dashboardData.user.lastName}`,
							rating: 0, // Would come from user rating system
							totalExchanges: dashboardData.stats.completedTransactions,
							joinDate: new Date(dashboardData.user.dateCreated).toLocaleDateString('en-US', { month: 'long', year: 'numeric' })
						};
					}
					

					
					// Update my listings
					if (dashboardData && dashboardData.recentListings) {
						myListings = dashboardData.recentListings.map(listing => ({
							id: listing.listingId,
							haveCurrency: listing.currency,
							haveAmount: listing.amount,
							wantCurrency: listing.acceptCurrency,
							wantAmount: 0, // Would need exchange rate calculation
							location: listing.location,
							radius: 5,
							status: listing.status,
							createdDate: new Date(listing.createdAt).toLocaleDateString(),
							expiresDate: new Date(listing.availableUntil).toLocaleDateString(),
							viewCount: 0, // Would come from analytics
							contactCount: 0 // Would come from analytics
						}));
					}
					
				} else {
					error = response ? response.error : 'Failed to load dashboard data';
				}
				isLoading = false;
			});
			
			console.log('[Dashboard] About to call handleGetPurchasedContacts...');
			// Load purchased contacts
			handleGetPurchasedContacts(sessionId, (response) => {
				console.log('[Dashboard] GetPurchasedContacts response:', response);
				if (response && response.success) {
					purchasedContacts = response.purchased_contacts || [];
					console.log('[Dashboard] Set purchasedContacts to:', purchasedContacts);
					console.log('[Dashboard] purchasedContacts length:', purchasedContacts.length);
					updateAllActiveExchanges();
				} else {
					console.error('[Dashboard] Failed to load purchased contacts:', response);
				}
			});
			
			console.log('[Dashboard] About to call handleGetListingPurchases...');
			// Load listing purchases (buyers who purchased access to user's listings)
			handleGetListingPurchases(sessionId, (response) => {
				console.log('[Dashboard] GetListingPurchases response:', response);
				if (response && response.success) {
					listingPurchases = response.listing_purchases || [];
					console.log('[Dashboard] Set listingPurchases to:', listingPurchases);
					updateAllActiveExchanges();
				} else {
					console.error('[Dashboard] Failed to load listing purchases:', response);
				}
			});
			
		} catch (err) {
			console.error('[Dashboard] Error in onMount:', err);
			console.error('[Dashboard] Error stack:', err.stack);
			error = 'An error occurred while loading dashboard data';
			isLoading = false;
		}
	});
	
	function handleCreateListing() {
		goto('/create-listing');
	}
	
	function handleSearchCurrency() {
		goto('/search');
	}
	
	function handleViewMessages() {
		goto('/messages');
	}
	
	function handleViewProfile() {
		goto('/profile');
	}
	
	function handleViewListing(listingId) {
		goto(`/listing/${listingId}`);
	}
	

	
	// Contact and messaging functions
	async function openConversation(contact, role = 'buyer') {
		selectedConversation = { ...contact, role };
		showMessaging = true;
		await loadMessages(contact.listing_id);
	}
	
	async function loadMessages(listingId) {
		const sessionId = Session.SessionId;
		await handleGetContactMessages(sessionId, listingId, (response) => {
			if (response && response.success) {
				conversationMessages = response.messages || [];
			} else {
				console.error('Failed to load messages:', response?.error);
			}
		});
	}
	
	async function sendMessage() {
		if (!newMessage.trim() || !selectedConversation) return;
		
		const sessionId = Session.SessionId;
		await handleSendContactMessage(sessionId, selectedConversation.listing_id, newMessage, (response) => {
			if (response && response.success) {
				newMessage = '';
				// Reload messages to show the new one
				loadMessages(selectedConversation.listing_id);
			} else {
				console.error('Failed to send message:', response?.error);
			}
		});
	}
	
	function closeMessaging() {
		showMessaging = false;
		selectedConversation = null;
		conversationMessages = [];
		newMessage = '';
	}



	function openContactDetails(contact, role = 'buyer') {
		// Store contact data in sessionStorage to pass to the dedicated page
		sessionStorage.setItem('contactData', JSON.stringify({ ...contact, role }));
		// Navigate to the dedicated contact details page
		goto(`/contact/${contact.listing_id}`);
	}



	function switchTab(tab) {
		activeTab = tab;
	}
	
	function handleLogout() {
		// Clear authentication cookies
		Cookies.remove("SessionId");
		Cookies.remove("UserType");
		// Redirect to login page
		goto('/login');
	}

	// Listing management functions
	function editListing(listingId) {
		goto(`/edit-listing/${listingId}`);
	}
	


	function deleteListing(listingId) {
		if (confirm('Are you sure you want to delete this listing?')) {
			myListings = myListings.filter(listing => listing.id !== listingId);
		}
	}

	function extendListing(listingId) {
		const listing = myListings.find(l => l.id === listingId);
		if (listing) {
			// Extend by 7 days
			const newExpireDate = new Date(listing.expiresDate);
			newExpireDate.setDate(newExpireDate.getDate() + 7);
			listing.expiresDate = newExpireDate.toISOString().split('T')[0];
			listing.status = 'active';
			myListings = myListings; // Trigger reactivity
			alert('Listing extended by 7 days!');
		}
	}

	function formatDate(dateString) {
		return new Date(dateString).toLocaleDateString();
	}

	// Helper function to get flag image source
	function getFlagImage(currencyCode) {
		return `/images/flags/${currencyCode.toLowerCase()}.png`;
	}
	
	// Helper function to format location display (remove lat/lng coordinates)
	function formatLocationForDisplay(location) {
		if (!location) return 'Location not specified';
		
		// Check if location contains coordinates (lat, lng format)
		if (location.includes(',') && /^-?\d+\.?\d*,\s*-?\d+\.?\d*$/.test(location.trim())) {
			// It's coordinates, return generic location
			return 'Location available';
		}
		
		// It's already a formatted location string
		return location;
	}
	
</script>

<svelte:head>
	<title>Dashboard - NICE Traders</title>
	<meta name="description" content="Your NICE Traders dashboard - manage currency exchanges" />
</svelte:head>

{#if isLoading}
	<div class="loading-container">
		<div class="loading-spinner"></div>
		<p>Loading your dashboard...</p>
	</div>
{:else if error}
	<div class="error-container">
		<h2>Error Loading Dashboard</h2>
		<p>{error}</p>
		<button on:click={() => window.location.reload()} class="retry-button">Retry</button>
	</div>
{:else}
<main class="dashboard-container">
	<div class="header">
		<div class="user-info">
			<div class="avatar">
				{user.name.split(' ').map(n => n[0]).join('')}
			</div>
			<div class="user-details">
				<h1 class="user-name">Welcome, {user.name.split(' ')[0]}</h1>
				<div class="user-stats">
					<span class="rating">⭐ {user.rating}</span>
					<span class="exchanges">{user.totalExchanges} exchanges</span>
				</div>
			</div>
		</div>
		<button class="profile-button" on:click={handleViewProfile}>
			<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
				<path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
				<circle cx="12" cy="7" r="4"></circle>
			</svg>
		</button>
	</div>

	<div class="content">
		<!-- Quick Actions -->
		<section class="quick-actions">
			<h2 class="section-title">Quick Actions</h2>
			<div class="action-buttons">
				<button class="action-button primary" on:click={handleCreateListing}>
					<div class="action-icon">💰</div>
					<span class="action-text">List Currency</span>
				</button>
				<button class="action-button secondary" on:click={handleSearchCurrency}>
					<div class="action-icon">🔍</div>
					<span class="action-text">Search</span>
				</button>
				<button class="action-button secondary" on:click={handleViewMessages}>
					<div class="action-icon">💬</div>
					<span class="action-text">Messages</span>
				</button>
			</div>
		</section>

		<!-- Priority: All Active Exchanges (Most Important) -->
		<section class="priority-contacts">
			<div class="section-header">
				<h2 class="section-title">🤝 All Active Exchanges ({allActiveExchanges.length})</h2>
				<span class="priority-badge">Priority</span>
			</div>
			
			{#if allActiveExchanges.length > 0}
				<div class="priority-contacts-grid">
					{#each allActiveExchanges as contact}
						<div class="priority-contact-card" on:click={() => openContactDetails(contact, contact.type)}>
							<div class="contact-priority-header">
								<div class="currency-exchange">
									<span class="currency-from">{contact.listing.currency}</span>
									<span class="exchange-arrow">→</span>
									<span class="currency-to">{contact.listing.accept_currency || contact.listing.preferred_currency}</span>
								</div>
								<div class="exchange-amount">${contact.listing.amount}</div>
							</div>
							
				<div class="contact-trader">
					<div class="trader-name">{contact.type === 'buyer' ? contact.seller?.name : contact.buyer?.name}</div>
					<div class="trader-location">{formatLocationForDisplay(contact.listing.location)}</div>
				</div>							<div class="contact-status">
								<div class="purchase-info">
									<span class="exchange-type">{contact.type === 'buyer' ? 'Buying from' : 'Selling to'}</span>
									{#if contact.purchased_at}
										Purchased {new Date(contact.purchased_at).toLocaleDateString()}
									{/if}
								</div>
								{#if contact.conversation?.message_count > 0}
									<div class="message-indicator">
										💬 {contact.conversation.message_count} messages
									</div>
								{:else}
									<div class="message-indicator new">
										💬 Start conversation
									</div>
								{/if}
							</div>
						</div>
					{/each}
				</div>
			{:else}
				<div class="empty-priority">
					<div class="empty-icon">🔍</div>
					<h3>No Active Exchanges</h3>
					<p>Browse listings and purchase contact access to start exchanging currencies</p>
					<button class="browse-listings-btn" on:click={() => goto('/search')}>Browse Listings</button>
				</div>
			{/if}
		</section>

		<!-- My Active Listings -->
		<section class="my-listings">
			<div class="section-header">
				<h2 class="section-title">My Active Listings ({myListings.length})</h2>
			</div>
			
			{#if myListings.length > 0}
				<div class="listings-container">
					{#each myListings as listing}
						<div class="user-listing-card">
							<div class="listing-exchange">
								<div class="currency-pair">
									<div class="currency-from">
										<img src={getFlagImage(listing.haveCurrency)} alt="{listing.haveCurrency} flag" class="currency-flag" />
										<span class="currency-amount">{listing.haveAmount} {listing.haveCurrency}</span>
									</div>
									<div class="exchange-arrow">→</div>
									<div class="currency-to">
										<img src={getFlagImage(listing.wantCurrency)} alt="{listing.wantCurrency} flag" class="currency-flag" />
										<span class="currency-amount">{listing.wantAmount} {listing.wantCurrency}</span>
									</div>
								</div>
								<div class="listing-status active">ACTIVE</div>
							</div>

							<div class="listing-stats">
								<div class="stat">
									<span class="stat-icon">👁️</span>
									<span class="stat-text">{listing.viewCount} views</span>
								</div>
								<div class="stat">
									<span class="stat-icon">💬</span>
									<span class="stat-text">{listing.contactCount} contacts</span>
								</div>
								<div class="stat">
									<span class="stat-icon">📍</span>
									<span class="stat-text">{listing.radius}mi radius</span>
								</div>
							</div>

							<div class="listing-info">
								<div class="info-row">
									<span class="info-label">Expires:</span>
									<span class="info-value">{formatDate(listing.expiresDate)}</span>
								</div>
							</div>

							<div class="listing-actions">
								<button class="action-btn edit" on:click={() => editListing(listing.id)}>
									Edit Listing
								</button>
							</div>
						</div>
					{/each}
				</div>
			{:else}
				<div class="empty-state">
					<div class="empty-icon">📝</div>
					<p class="empty-text">No active listings yet</p>
					<button class="empty-action" on:click={handleCreateListing}>Create Your First Listing</button>
				</div>
			{/if}
		</section>





	</div>

	<!-- Messaging Modal -->
	{#if showMessaging && selectedConversation}
		<div class="messaging-overlay" on:click={closeMessaging}>
			<div class="messaging-modal" on:click|stopPropagation>
				<div class="messaging-header">
					<div class="conversation-info">
						<h3>{selectedConversation.listing.currency} → {selectedConversation.listing.accept_currency}</h3>
						<p>
							{#if selectedConversation.role === 'buyer'}
								Conversation with {selectedConversation.seller?.name || selectedConversation.buyer?.name}
							{:else}
								Conversation with {selectedConversation.buyer?.name || selectedConversation.seller?.name}
							{/if}
						</p>
					</div>
					<button class="close-button" on:click={closeMessaging}>✕</button>
				</div>
				
				<div class="messages-container">
					{#if conversationMessages.length > 0}
						{#each conversationMessages as message}
							<div class="message {message.is_from_me ? 'sent' : 'received'}">
								<div class="message-content">
									<p>{message.message_text}</p>
									<span class="message-time">{new Date(message.sent_at).toLocaleString()}</span>
								</div>
							</div>
						{/each}
					{:else}
						<div class="no-messages">
							<p>No messages yet. Start the conversation!</p>
						</div>
					{/if}
				</div>
				
				<div class="message-input-container">
					<div class="message-input-wrapper">
						<textarea 
							bind:value={newMessage} 
							placeholder="Type your message..."
							class="message-input"
							rows="3"
							on:keydown={(e) => e.key === 'Enter' && !e.shiftKey && (e.preventDefault(), sendMessage())}
						></textarea>
						<button class="send-button" on:click={sendMessage} disabled={!newMessage.trim()}>
							Send
						</button>
					</div>
				</div>
			</div>
		</div>
	{/if}

	<!-- Bottom Navigation -->

	<!-- Bottom Navigation -->
	<nav class="bottom-nav">
		<button class="nav-item active">
			<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
				<path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path>
			</svg>
			<span>Home</span>
		</button>
		<button class="nav-item" on:click={handleSearchCurrency}>
			<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
				<circle cx="11" cy="11" r="8"></circle>
				<path d="M21 21l-4.35-4.35"></path>
			</svg>
			<span>Search</span>
		</button>
		<button class="nav-item" on:click={handleCreateListing}>
			<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
				<circle cx="12" cy="12" r="10"></circle>
				<line x1="12" y1="8" x2="12" y2="16"></line>
				<line x1="8" y1="12" x2="16" y2="12"></line>
			</svg>
			<span>List</span>
		</button>
		<button class="nav-item" on:click={handleViewMessages}>
			<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
				<path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path>
			</svg>
			<span>Messages</span>
		</button>
		<button class="nav-item" on:click={handleLogout}>
			<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
				<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path>
				<polyline points="16,17 21,12 16,7"></polyline>
				<line x1="21" y1="12" x2="9" y2="12"></line>
			</svg>
			<span>Logout</span>
		</button>
	</nav>
</main>
{/if}

<style>
	/* Loading and error states */
	.loading-container, .error-container {
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		min-height: 60vh;
		text-align: center;
		padding: 2rem;
	}
	
	.loading-spinner {
		width: 40px;
		height: 40px;
		border: 4px solid #f3f4f6;
		border-top: 4px solid #667eea;
		border-radius: 50%;
		animation: spin 1s linear infinite;
		margin-bottom: 1rem;
	}
	
	@keyframes spin {
		0% { transform: rotate(0deg); }
		100% { transform: rotate(360deg); }
	}
	
	.error-container h2 {
		color: #ef4444;
		margin-bottom: 1rem;
	}
	
	.retry-button {
		background: #667eea;
		color: white;
		border: none;
		padding: 0.75rem 1.5rem;
		border-radius: 8px;
		cursor: pointer;
		font-weight: 600;
		margin-top: 1rem;
	}
	
	.retry-button:hover {
		background: #5a67d8;
	}
	
	.dashboard-container {
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
		padding: 1.5rem 1.5rem 2rem;
		display: flex;
		align-items: center;
		justify-content: space-between;
	}

	.user-info {
		display: flex;
		align-items: center;
		gap: 1rem;
	}

	.avatar {
		width: 50px;
		height: 50px;
		background: rgba(255, 255, 255, 0.2);
		border-radius: 50%;
		display: flex;
		align-items: center;
		justify-content: center;
		font-weight: 600;
		font-size: 1.1rem;
	}

	.user-name {
		font-size: 1.3rem;
		font-weight: 600;
		margin: 0 0 0.25rem;
	}

	.user-stats {
		display: flex;
		gap: 1rem;
		font-size: 0.85rem;
		opacity: 0.9;
	}

	.profile-button {
		background: rgba(255, 255, 255, 0.2);
		border: none;
		color: white;
		width: 44px;
		height: 44px;
		border-radius: 12px;
		display: flex;
		align-items: center;
		justify-content: center;
		cursor: pointer;
		transition: background-color 0.2s;
	}

	.profile-button:hover {
		background: rgba(255, 255, 255, 0.3);
	}

	.content {
		flex: 1;
		padding: 1.5rem 1.5rem 5rem;
		overflow-y: auto;
	}

	.section-title {
		font-size: 1.2rem;
		font-weight: 600;
		color: #2d3748;
		margin: 0 0 1rem;
	}

	.section-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 1rem;
	}

	.view-all-link {
		background: none;
		border: none;
		color: #667eea;
		font-size: 0.9rem;
		font-weight: 500;
		cursor: pointer;
		text-decoration: none;
	}

	.view-all-link:hover {
		text-decoration: underline;
	}

	/* Quick Actions */
	.quick-actions {
		margin-bottom: 2rem;
	}

	.action-buttons {
		display: flex;
		gap: 1rem;
	}

	.action-button {
		flex: 1;
		padding: 1rem;
		border: none;
		border-radius: 12px;
		cursor: pointer;
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 0.5rem;
		transition: transform 0.2s, box-shadow 0.2s;
	}

	.action-button.primary {
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		color: white;
		box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
	}

	.action-button.secondary {
		background: white;
		color: #4a5568;
		border: 2px solid #e2e8f0;
	}

	.action-button:hover {
		transform: translateY(-2px);
	}

	.action-button.primary:hover {
		box-shadow: 0 8px 25px rgba(102, 126, 234, 0.4);
	}

	.action-icon {
		font-size: 1.5rem;
	}

	.action-text {
		font-size: 0.9rem;
		font-weight: 500;
	}

	/* My Listings */
	.my-listings {
		margin-bottom: 2rem;
	}

	.listings-container {
		display: flex;
		flex-direction: column;
		gap: 1rem;
	}

	.user-listing-card {
		background: white;
		border-radius: 16px;
		padding: 1rem;
		border: 1px solid #e2e8f0;
		box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
	}

	.listing-exchange {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 1rem;
	}

	.currency-pair {
		display: flex;
		align-items: center;
		gap: 0.75rem;
		flex: 1;
	}

	.currency-from, .currency-to {
		display: flex;
		align-items: center;
		gap: 0.5rem;
	}

	.currency-flag {
		width: 20px;
		height: 15px;
		object-fit: cover;
		border-radius: 2px;
		border: 1px solid #e2e8f0;
	}

	.currency-amount {
		font-weight: 600;
		color: #2d3748;
		font-size: 0.9rem;
	}

	.exchange-arrow {
		color: #667eea;
		font-weight: 600;
		margin: 0 0.25rem;
	}

	.listing-status.active {
		background: #10b981;
		color: white;
		padding: 0.25rem 0.5rem;
		border-radius: 12px;
		font-size: 0.7rem;
		font-weight: 600;
		letter-spacing: 0.5px;
	}

	.listing-stats {
		display: flex;
		gap: 1rem;
		margin-bottom: 0.75rem;
		padding: 0.5rem;
		background: #f8fafc;
		border-radius: 8px;
	}

	.stat {
		display: flex;
		align-items: center;
		gap: 0.25rem;
	}

	.stat-icon {
		font-size: 0.8rem;
	}

	.stat-text {
		font-size: 0.75rem;
		color: #4a5568;
		font-weight: 500;
	}

	.listing-info {
		margin-bottom: 1rem;
	}

	.info-row {
		display: flex;
		justify-content: space-between;
		align-items: center;
	}

	.info-label {
		font-size: 0.8rem;
		color: #718096;
		font-weight: 500;
	}

	.info-value {
		font-size: 0.8rem;
		color: #2d3748;
		font-weight: 500;
	}

	.listing-actions {
		display: flex;
		gap: 0.5rem;
	}

	.action-btn {
		flex: 1;
		padding: 0.5rem;
		border: none;
		border-radius: 8px;
		font-weight: 600;
		font-size: 0.8rem;
		cursor: pointer;
		transition: transform 0.2s;
	}

	.action-btn:hover {
		transform: translateY(-1px);
	}

	.action-btn.edit {
		background: #667eea;
		color: white;
	}

	.action-btn.delete {
		background: #ef4444;
		color: white;
	}

	.listing-details {
		display: flex;
		justify-content: space-between;
		font-size: 0.85rem;
		color: #718096;
		margin-bottom: 0.5rem;
	}

	.listing-date {
		font-size: 0.8rem;
		color: #a0aec0;
	}

	/* Empty State */
	.empty-state {
		text-align: center;
		padding: 2rem;
		background: white;
		border-radius: 12px;
		border: 2px dashed #e2e8f0;
	}

	.empty-icon {
		font-size: 3rem;
		margin-bottom: 1rem;
	}

	.empty-text {
		color: #718096;
		margin-bottom: 1rem;
	}

	.empty-action {
		background: #667eea;
		color: white;
		border: none;
		padding: 0.75rem 1.5rem;
		border-radius: 8px;
		cursor: pointer;
		font-weight: 500;
	}

	/* Nearby Opportunities */


	/* Bottom Navigation */
	.bottom-nav {
		background: white;
		border-top: 1px solid #e2e8f0;
		display: flex;
		justify-content: space-around;
		padding: 0.75rem 0;
		position: fixed;
		bottom: 0;
		left: 50%;
		transform: translateX(-50%);
		width: 100%;
		max-width: 414px;
		z-index: 10;
	}

	.nav-item {
		background: none;
		border: none;
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 0.25rem;
		cursor: pointer;
		color: #a0aec0;
		font-size: 0.75rem;
		padding: 0.5rem;
		transition: color 0.2s;
	}

	.nav-item.active {
		color: #667eea;
	}

	.nav-item:hover {
		color: #667eea;
	}

	/* Responsive adjustments */
	@media (max-width: 375px) {
		.dashboard-container {
			max-width: 375px;
		}
		
		.content {
			padding: 1rem 1rem 5rem;
		}
		
		.header {
			padding: 1.25rem 1rem 1.5rem;
		}
		
		.user-name {
			font-size: 1.2rem;
		}
		
		.action-buttons {
			gap: 0.75rem;
		}
	}

	@media (max-width: 320px) {
		.dashboard-container {
			max-width: 320px;
		}
		
		.content {
			padding: 1rem 0.75rem 5rem;
		}
		
		.header {
			padding: 1rem 0.75rem 1.25rem;
		}
		
		.action-buttons {
			flex-direction: column;
			gap: 0.75rem;
		}
		
		.action-button {
			flex-direction: row;
			justify-content: center;
		}
	}

	/* Contact sections */
	.purchased-contacts, .listing-purchases {
		margin-bottom: 2rem;
	}

	.contacts-list, .purchases-list {
		display: flex;
		flex-direction: column;
		gap: 1rem;
	}

	.contact-card, .purchase-card {
		background: var(--surface-color);
		border: 1px solid var(--border-color);
		border-radius: 12px;
		padding: 1.5rem;
		display: flex;
		justify-content: space-between;
		align-items: flex-start;
		gap: 1rem;
	}

	.contact-info, .purchase-info {
		flex: 1;
	}

	.contact-header, .purchase-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 0.5rem;
	}

	.currency-pair {
		font-weight: 600;
		color: var(--primary-color);
		font-size: 1.1rem;
	}

	.contact-amount, .purchase-amount {
		font-weight: 600;
		color: var(--accent-color);
		font-size: 1.1rem;
	}

	.contact-seller, .purchase-buyer {
		margin-bottom: 0.5rem;
		color: var(--text-color);
	}

	.contact-location, .purchase-location {
		color: var(--muted-color);
		font-size: 0.9rem;
		margin-left: 0.5rem;
	}

	.contact-purchased, .purchase-date {
		font-size: 0.9rem;
		color: var(--muted-color);
		margin-bottom: 0.5rem;
	}

	.contact-messages, .purchase-messages {
		font-size: 0.9rem;
		color: var(--muted-color);
	}

	.contact-button, .purchase-button {
		background: var(--primary-color);
		color: white;
		border: none;
		border-radius: 8px;
		padding: 0.75rem 1.5rem;
		font-weight: 600;
		cursor: pointer;
		transition: background-color 0.2s;
		white-space: nowrap;
	}

	.contact-button:hover, .purchase-button:hover {
		background: var(--primary-hover);
	}

	/* Messaging Modal */
	.messaging-overlay {
		position: fixed;
		top: 0;
		left: 0;
		right: 0;
		bottom: 0;
		background: rgba(0, 0, 0, 0.7);
		display: flex;
		align-items: center;
		justify-content: center;
		z-index: 1000;
	}

	.messaging-modal {
		background: var(--surface-color);
		border-radius: 16px;
		width: 90%;
		max-width: 600px;
		max-height: 80vh;
		display: flex;
		flex-direction: column;
		box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
	}

	.messaging-header {
		padding: 1.5rem;
		border-bottom: 1px solid var(--border-color);
		display: flex;
		justify-content: space-between;
		align-items: flex-start;
	}

	.conversation-info h3 {
		margin: 0 0 0.5rem 0;
		color: var(--primary-color);
		font-size: 1.2rem;
	}

	.conversation-info p {
		margin: 0;
		color: var(--muted-color);
		font-size: 0.9rem;
	}

	.close-button {
		background: none;
		border: none;
		font-size: 1.5rem;
		cursor: pointer;
		color: var(--muted-color);
		padding: 0.5rem;
		border-radius: 50%;
		display: flex;
		align-items: center;
		justify-content: center;
		width: 2rem;
		height: 2rem;
	}

	.close-button:hover {
		background: var(--hover-color);
		color: var(--text-color);
	}

	.messages-container {
		flex: 1;
		padding: 1rem;
		overflow-y: auto;
		display: flex;
		flex-direction: column;
		gap: 1rem;
		max-height: 400px;
	}

	.message {
		display: flex;
		margin-bottom: 0.5rem;
	}

	.message.sent {
		justify-content: flex-end;
	}

	.message.received {
		justify-content: flex-start;
	}

	.message-content {
		max-width: 70%;
		padding: 0.75rem 1rem;
		border-radius: 12px;
		position: relative;
	}

	.message.sent .message-content {
		background: var(--primary-color);
		color: white;
		border-bottom-right-radius: 4px;
	}

	.message.received .message-content {
		background: var(--surface-alt);
		color: var(--text-color);
		border-bottom-left-radius: 4px;
	}

	.message-content p {
		margin: 0;
		word-wrap: break-word;
	}

	.message-time {
		font-size: 0.75rem;
		opacity: 0.7;
		display: block;
		margin-top: 0.25rem;
	}

	.no-messages {
		text-align: center;
		color: var(--muted-color);
		padding: 2rem;
	}

	.message-input-container {
		padding: 1rem 1.5rem;
		border-top: 1px solid var(--border-color);
	}

	.message-input-wrapper {
		display: flex;
		gap: 1rem;
		align-items: flex-end;
	}

	.message-input {
		flex: 1;
		border: 1px solid var(--border-color);
		border-radius: 8px;
		padding: 0.75rem;
		resize: none;
		font-family: inherit;
		font-size: 0.9rem;
		background: var(--background-color);
		color: var(--text-color);
	}

	.message-input:focus {
		outline: none;
		border-color: var(--primary-color);
	}

	.send-button {
		background: var(--primary-color);
		color: white;
		border: none;
		border-radius: 8px;
		padding: 0.75rem 1.5rem;
		font-weight: 600;
		cursor: pointer;
		transition: background-color 0.2s;
		align-self: flex-end;
	}

	.send-button:hover:not(:disabled) {
		background: var(--primary-hover);
	}

	.send-button:disabled {
		background: var(--muted-color);
		cursor: not-allowed;
	}

	.empty-text-small {
		font-size: 0.9rem;
		color: var(--muted-color);
		margin-top: 0.5rem;
	}

	/* Priority Contacts Section */
	.priority-contacts {
		margin-bottom: 2rem;
		padding: 1.5rem;
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		border-radius: 16px;
		color: white;
	}

	.priority-contacts .section-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 1.5rem;
	}

	.priority-badge {
		background: rgba(255, 255, 255, 0.2);
		padding: 0.25rem 0.75rem;
		border-radius: 20px;
		font-size: 0.8rem;
		font-weight: 600;
		text-transform: uppercase;
		letter-spacing: 0.5px;
	}

	.priority-contacts-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
		gap: 1rem;
	}

	.priority-contact-card {
		background: rgba(255, 255, 255, 0.1);
		backdrop-filter: blur(10px);
		border: 1px solid rgba(255, 255, 255, 0.2);
		border-radius: 12px;
		padding: 1.5rem;
		cursor: pointer;
		transition: all 0.3s ease;
	}

	.priority-contact-card:hover {
		background: rgba(255, 255, 255, 0.15);
		transform: translateY(-2px);
		box-shadow: 0 8px 25px rgba(0, 0, 0, 0.15);
	}

	.contact-priority-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 1rem;
	}

	.currency-exchange {
		display: flex;
		align-items: center;
		gap: 0.5rem;
	}

	.currency-from, .currency-to {
		font-weight: 700;
		font-size: 1.1rem;
	}

	.exchange-arrow {
		font-size: 1.2rem;
		opacity: 0.8;
	}

	.exchange-amount {
		font-size: 1.3rem;
		font-weight: 700;
		color: #FFD700;
	}

	.contact-trader {
		margin-bottom: 1rem;
	}

	.trader-name {
		font-size: 1.1rem;
		font-weight: 600;
		margin-bottom: 0.25rem;
	}

	.trader-location {
		opacity: 0.8;
		font-size: 0.9rem;
	}

	.contact-status {
		display: flex;
		justify-content: space-between;
		align-items: center;
		font-size: 0.9rem;
	}

	.message-indicator {
		background: rgba(255, 255, 255, 0.2);
		padding: 0.25rem 0.75rem;
		border-radius: 15px;
		font-size: 0.8rem;
	}

	.message-indicator.new {
		background: #FFD700;
		color: #333;
		font-weight: 600;
	}

	.empty-priority {
		text-align: center;
		padding: 3rem 1rem;
		color: rgba(255, 255, 255, 0.9);
	}

	.empty-priority .empty-icon {
		font-size: 3rem;
		margin-bottom: 1rem;
	}

	.empty-priority h3 {
		margin: 0 0 0.5rem 0;
		font-size: 1.3rem;
	}

	.empty-priority p {
		margin: 0 0 1.5rem 0;
		opacity: 0.8;
	}

	.browse-listings-btn {
		background: rgba(255, 255, 255, 0.2);
		color: white;
		border: 1px solid rgba(255, 255, 255, 0.3);
		padding: 0.75rem 2rem;
		border-radius: 25px;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.3s ease;
	}

	.browse-listings-btn:hover {
		background: rgba(255, 255, 255, 0.3);
		transform: translateY(-1px);
	}

	/* Contact Details Modal */
	.contact-details-overlay {
		position: fixed;
		top: 0;
		left: 0;
		right: 0;
		bottom: 0;
		background: rgba(0, 0, 0, 0.8);
		display: flex;
		align-items: center;
		justify-content: center;
		z-index: 1000;
		padding: 1rem;
	}

	.contact-details-modal {
		background: var(--surface-color);
		border-radius: 20px;
		width: 100%;
		max-width: 900px;
		max-height: 90vh;
		display: flex;
		flex-direction: column;
		box-shadow: 0 25px 80px rgba(0, 0, 0, 0.3);
		overflow: hidden;
	}

	.contact-details-header {
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		color: white;
		padding: 2rem;
		display: flex;
		justify-content: space-between;
		align-items: flex-start;
	}

	.exchange-overview h2 {
		margin: 0 0 0.5rem 0;
		font-size: 1.8rem;
		font-weight: 700;
	}

	.exchange-overview .exchange-amount {
		font-size: 1.4rem;
		font-weight: 600;
		color: #FFD700;
	}

	.trader-overview .trader-name {
		font-size: 1.1rem;
		font-weight: 600;
		margin-bottom: 0.25rem;
	}

	.location-overview {
		opacity: 0.9;
		font-size: 0.95rem;
	}

	.close-details-button {
		background: rgba(255, 255, 255, 0.2);
		border: none;
		color: white;
		font-size: 1.5rem;
		width: 40px;
		height: 40px;
		border-radius: 50%;
		cursor: pointer;
		display: flex;
		align-items: center;
		justify-content: center;
		transition: background-color 0.2s;
	}

	.close-details-button:hover {
		background: rgba(255, 255, 255, 0.3);
	}

	/* Tab Navigation */
	.tab-navigation {
		display: flex;
		background: var(--surface-alt);
		border-bottom: 1px solid var(--border-color);
	}

	.tab-button {
		flex: 1;
		background: none;
		border: none;
		padding: 1rem 1.5rem;
		font-size: 0.9rem;
		font-weight: 600;
		color: var(--muted-color);
		cursor: pointer;
		transition: all 0.2s;
		border-bottom: 3px solid transparent;
	}

	.tab-button:hover {
		background: var(--hover-color);
		color: var(--text-color);
	}

	.tab-button.active {
		color: var(--primary-color);
		border-bottom-color: var(--primary-color);
		background: var(--surface-color);
	}

	/* Tab Content */
	.tab-content {
		flex: 1;
		overflow-y: auto;
		padding: 2rem;
	}

	.details-tab h3 {
		color: var(--primary-color);
		margin: 0 0 1.5rem 0;
		font-size: 1.3rem;
	}

	.detail-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
		gap: 1rem;
		margin-bottom: 2rem;
	}

	.detail-item {
		background: var(--surface-alt);
		padding: 1rem;
		border-radius: 8px;
		border-left: 4px solid var(--primary-color);
	}

	.detail-item label {
		display: block;
		font-size: 0.85rem;
		font-weight: 600;
		color: var(--muted-color);
		text-transform: uppercase;
		letter-spacing: 0.5px;
		margin-bottom: 0.5rem;
	}

	.detail-value {
		font-size: 1rem;
		font-weight: 600;
		color: var(--text-color);
	}

	.next-steps {
		display: flex;
		flex-direction: column;
		gap: 1rem;
	}

	.step {
		display: flex;
		align-items: flex-start;
		gap: 1rem;
		padding: 1rem;
		background: var(--surface-alt);
		border-radius: 8px;
	}

	.step-number {
		background: var(--primary-color);
		color: white;
		width: 2rem;
		height: 2rem;
		border-radius: 50%;
		display: flex;
		align-items: center;
		justify-content: center;
		font-weight: 700;
		flex-shrink: 0;
	}

	.step-content strong {
		display: block;
		margin-bottom: 0.25rem;
		color: var(--text-color);
	}

	.step-content p {
		margin: 0;
		color: var(--muted-color);
		font-size: 0.9rem;
	}

	/* Location Tab */
	.location-tab h3 {
		color: var(--primary-color);
		margin: 0 0 1.5rem 0;
		font-size: 1.3rem;
	}

	.location-status {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
		gap: 1rem;
		margin-bottom: 2rem;
	}

	.status-item {
		background: var(--surface-alt);
		padding: 1rem;
		border-radius: 8px;
	}

	.status-item label {
		display: block;
		font-size: 0.85rem;
		font-weight: 600;
		color: var(--muted-color);
		text-transform: uppercase;
		letter-spacing: 0.5px;
		margin-bottom: 0.5rem;
	}

	.status-value {
		font-weight: 600;
		color: var(--text-color);
	}

	.status-value.pending {
		color: var(--accent-color);
	}

	.map-placeholder {
		background: var(--surface-alt);
		border: 2px dashed var(--border-color);
		border-radius: 12px;
		padding: 2rem;
		text-align: center;
		margin-bottom: 2rem;
	}

	.map-icon {
		font-size: 3rem;
		margin-bottom: 1rem;
	}

	.map-placeholder h4 {
		margin: 0 0 1rem 0;
		color: var(--text-color);
	}

	.map-placeholder p {
		margin: 0 0 1rem 0;
		color: var(--muted-color);
	}

	.map-placeholder ul {
		text-align: left;
		display: inline-block;
		color: var(--muted-color);
	}

	.location-actions {
		display: flex;
		gap: 1rem;
		flex-wrap: wrap;
	}

	.location-button {
		background: var(--primary-color);
		color: white;
		border: none;
		padding: 0.75rem 1.5rem;
		border-radius: 8px;
		font-weight: 600;
		cursor: pointer;
		transition: background-color 0.2s;
	}

	.location-button:hover {
		background: var(--primary-hover);
	}

	/* Messages Tab */
	.messages-container-tab {
		height: 300px;
		overflow-y: auto;
		padding: 1rem;
		background: var(--surface-alt);
		border-radius: 8px;
		margin-bottom: 1rem;
	}

	@media (max-width: 768px) {
		.priority-contacts-grid {
			grid-template-columns: 1fr;
		}
		
		.contact-details-modal {
			margin: 0;
			height: 100vh;
			border-radius: 0;
		}
		
		.tab-button {
			font-size: 0.8rem;
			padding: 0.75rem 0.5rem;
		}
		
		.detail-grid {
			grid-template-columns: 1fr;
		}
		
		.location-actions {
			flex-direction: column;
		}
	}

	.badge {
		padding: 4px 8px;
		border-radius: 12px;
		font-size: 12px;
		font-weight: 500;
		text-transform: uppercase;
	}

	.badge-buyer {
		background: #e3f2fd;
		color: #1976d2;
	}

	.badge-seller {
		background: #e8f5e8;
		color: #388e3c;
	}

	.badge-unread {
		background: #fff3e0;
		color: #f57c00;
	}
</style>