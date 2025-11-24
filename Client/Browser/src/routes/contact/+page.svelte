<script>
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';
	import { Session } from '../../Session.js';
	import { 
		handleGetContactDetails, 
		handleCheckContactAccess, 
		handlePurchaseContactAccess, 
		handleSendInterestMessage, 
		handleReportListing,
		getReportReasons 
	} from './handleContact.js';
	
	// Dynamic listing data from API
	let listing = null;
	let isLoading = true;
	let loadError = null;

	// Get listing ID from URL parameters
	let listingId = null;
	
	// Extract listing ID from URL (would normally come from route params)
	if (typeof window !== 'undefined') {
		const urlParams = new URLSearchParams(window.location.search);
		listingId = urlParams.get('id') || '7b3bc66a-d020-48a0-a56a-2323038e8015'; // Default to actual listing for testing
	}
	
	// Fee structure from API
	let contactFee = {
		price: 2.00,
		currency: 'USD',
		features: ['Direct contact with seller', 'Exchange coordination', 'Platform protection', 'Dispute resolution support']
	};
	

	let hasActiveContact = false; // Would check if user already paid for this contact

	
	// Helper function to get flag image source
	function getFlagImage(currencyCode) {
		return `/images/flags/${currencyCode.toLowerCase()}.png`;
	}
	
	function goBack() {
		goto('/search');
	}
	

	
	let isProcessingPayment = false;

	async function purchaseContact() {
		if (isProcessingPayment) return; // Prevent double-clicks
		
		isProcessingPayment = true;
		
		try {
			const sessionId = Session.SessionId;
			console.log('[PayPal] Processing payment...', { listingId, sessionId });
			
			const response = await handlePurchaseContactAccess(listingId, sessionId, 'paypal');
			console.log('[PayPal] Server response:', response);
			
			if (response.success) {
				hasActiveContact = true;
				
				// Show success message
				const transactionId = response.transaction_id || 'N/A';
				alert(`🎉 Payment Successful!\n\nTransaction: ${transactionId}\n\nYou now have access to contact ${listing.user.name}. Redirecting to your dashboard...`);
				
				// Redirect to dashboard to see the purchased listing
				goto('/dashboard');
			} else {
				alert(`❌ Payment Failed\n\n${response.error}\n\nPlease try again or contact support if the problem persists.`);
			}
		} catch (error) {
			console.error('Payment error:', error);
			alert('❌ Payment Processing Error\n\nThere was a problem processing your payment. Please check your internet connection and try again.');
		} finally {
			isProcessingPayment = false;
		}
	}
	
	let showReportModal = false;
	let reportReason = '';
	let reportDescription = '';
	
	function reportListing() {
		showReportModal = true;
	}
	
	async function submitReport() {
		if (!reportReason) {
			alert('Please select a reason for reporting.');
			return;
		}
		
		try {
			const sessionId = Session.SessionId;
			const response = await handleReportListing(
				listingId, 
				sessionId, 
				reportReason, 
				reportDescription
			);
			
			if (response.success) {
				alert('Report submitted successfully. Thank you for helping keep our platform safe.');
				showReportModal = false;
				reportReason = '';
				reportDescription = '';
			} else {
				alert(`Failed to submit report: ${response.error}`);
			}
		} catch (error) {
			console.error('Report submission error:', error);
			alert('Failed to submit report. Please try again.');
		}
	}
	
	function closeReportModal() {
		showReportModal = false;
		reportReason = '';
		reportDescription = '';
	}
	
	function blockUser() {
		alert(`${listing.user.name} would be blocked from contacting you\n\n(This is just a prototype)`);
	}
	
	// Get user's current location
	async function getUserLocation() {
		return new Promise((resolve) => {
			if (!navigator.geolocation) {
				resolve({ lat: null, lng: null });
				return;
			}
			
			navigator.geolocation.getCurrentPosition(
				(position) => {
					resolve({
						lat: position.coords.latitude,
						lng: position.coords.longitude
					});
				},
				(error) => {
					console.log('Location access denied or failed:', error.message);
					resolve({ lat: null, lng: null });
				},
				{ timeout: 5000, enableHighAccuracy: false, maximumAge: 300000 }
			);
		});
	}

	// Load contact details and check access status
	onMount(async () => {
		await Session.handleSession();
		Session.GetSessionId(); // This sets Session.SessionId
		const sessionId = Session.SessionId;
		
		if (!sessionId) {
			goto('/login');
			return;
		}
		
		if (!listingId) {
			loadError = 'No listing ID provided';
			isLoading = false;
			return;
		}
		
		try {
			// Get user's location for distance calculation
			const userLocation = await getUserLocation();
			
			// Load contact details (with user location for distance calculation)
			const detailsResponse = await handleGetContactDetails(listingId, sessionId, userLocation.lat, userLocation.lng);
			if (detailsResponse.success) {
				listing = detailsResponse.listing;
				contactFee = detailsResponse.contact_fee;
			} else {
				loadError = detailsResponse.error || 'Failed to load listing details';
			}
			
			// Check if user already has contact access
			const accessResponse = await handleCheckContactAccess(listingId, sessionId);
			if (accessResponse.success) {
				hasActiveContact = accessResponse.has_access;
			}
			
		} catch (error) {
			console.error('Error loading contact data:', error);
			loadError = 'Failed to load contact information';
		} finally {
			isLoading = false;
		}
	});
</script>

<svelte:head>
	<title>Contact {listing?.user?.name || 'Trader'} - NICE Traders</title>
	<meta name="description" content="Contact trader for currency exchange" />
</svelte:head>

<main class="contact-container">
	<div class="header">
		<button class="back-button" on:click={goBack} aria-label="Go back">
			<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
				<polyline points="15,18 9,12 15,6"></polyline>
			</svg>
		</button>
		<h1 class="page-title">Contact Trader</h1>
		<button class="menu-button" on:click={reportListing} aria-label="More options">
			<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
				<circle cx="12" cy="12" r="1"></circle>
				<circle cx="12" cy="5" r="1"></circle>
				<circle cx="12" cy="19" r="1"></circle>
			</svg>
		</button>
	</div>

	<div class="content">
		{#if isLoading}
			<div class="loading-state">
				<div class="loading-spinner"></div>
				<p>Loading contact details...</p>
			</div>
		{:else if loadError}
			<div class="error-state">
				<p class="error-message">{loadError}</p>
				<button class="retry-button" on:click={() => window.location.reload()}>Try Again</button>
			</div>
		{:else if listing}
		<!-- Listing Summary -->
		<div class="listing-summary">
			<div class="listing-header">
				<div class="currency-display">
					<img src={getFlagImage(listing.currency)} alt="{listing.currency} flag" class="currency-flag" />
					<div class="currency-info">
						<span class="currency-amount">{listing.amount} {listing.currency}</span>
						<span class="currency-rate">
							{#if listing.rate === 'market'}
								Market Rate
							{:else}
								${listing.customRate} per {listing.currency}
							{/if}
						</span>
					</div>
				</div>
				<div class="location-info">
					<span class="location">{listing.location}</span>
					<span class="radius">Within {listing.location_radius} miles</span>
				</div>
			</div>
		</div>

		<!-- Trader Profile -->
		<div class="trader-profile">
			<div class="profile-header">
				<div class="trader-info">
					<div class="trader-name">
						{listing.user.name}
						{#if listing.user.verified}
							<span class="verified-badge" title="Verified trader">✓</span>
						{/if}
					</div>
					<div class="trader-stats">
						<span class="rating">⭐ {listing.user.rating}</span>
						<span class="trades">{listing.user.trades} completed trades</span>
					</div>
				</div>
				<div class="trader-status">
					<span class="last-active">{listing.user.last_active}</span>
				</div>
			</div>

			<div class="profile-details">
				<div class="detail-grid">
					<div class="detail-item">
						<span class="detail-label">Member since:</span>
						<span class="detail-value">{listing.user.joined_date ? new Date(listing.user.joined_date).toLocaleDateString() : 'Unknown'}</span>
					</div>
					<div class="detail-item">
						<span class="detail-label">Response time:</span>
						<span class="detail-value">{listing.user.response_time}</span>
					</div>
					<div class="detail-item">
						<span class="detail-label">Languages:</span>
						<span class="detail-value">{listing.user.languages.join(', ')}</span>
					</div>
					<div class="detail-item">
						<span class="detail-label">Meeting preference:</span>
						<span class="detail-value">
							{listing.meetingPreference === 'public' ? 'Public places only' : 'Flexible locations'}
						</span>
					</div>
				</div>
			</div>
		</div>

		<!-- Contact Status -->
		{#if hasActiveContact}
			<div class="contact-status active">
				<div class="status-icon">✅</div>
				<div class="status-info">
					<h3 class="status-title">Contact Access Active</h3>
					<p class="status-text">You can communicate directly with {listing.user.name} and coordinate your exchange.</p>
				</div>
			</div>
		{:else}
			<div class="contact-status limited">
				<div class="status-icon">💰</div>
				<div class="status-info">
					<h3 class="status-title">Contact Access Required</h3>
					<p class="status-text">Pay $2.00 to contact {listing.user.name} and coordinate your exchange.</p>
				</div>
			</div>
		{/if}

		<!-- Full Contact Section -->
		<div class="full-contact">
			<h3 class="section-title">
				{#if hasActiveContact}
					Direct Contact
				{:else}
					Unlock Full Contact
				{/if}
			</h3>
			
			{#if hasActiveContact}
				<div class="messaging-section">
					<h4 class="subsection-title">Messages</h4>
					<div class="message-thread">
						<p class="no-messages">No messages yet. Start a conversation below!</p>
					</div>
					<div class="message-compose">
						<textarea 
							class="message-input" 
							placeholder="Type your message to {listing.user.name}..."
							rows="3"
						></textarea>
						<button class="send-message-button">Send Message</button>
					</div>
				</div>

				<div class="meeting-proposal-section">
					<h4 class="subsection-title">Propose a Meeting</h4>
					<div class="meeting-form">
						<div class="form-group">
							<label class="form-label">Date & Time</label>
							<input type="datetime-local" class="form-input" />
						</div>
						<div class="form-group">
							<label class="form-label">Meeting Location</label>
							<input type="text" class="form-input" placeholder="Suggest a meeting place..." />
						</div>
						<button class="propose-meeting-button">Propose Meeting</button>
					</div>
				</div>
			{:else}
				<p class="section-subtitle">Pay once to get full contact access and coordinate your exchange</p>
				
				<div class="pricing-card">
					<div class="plan-header">
						<h4 class="plan-name">Contact Access</h4>
						<span class="plan-price">${contactFee.price}</span>
					</div>
					<ul class="plan-features">
						{#each contactFee.features as feature}
							<li class="plan-feature">✓ {feature}</li>
						{/each}
					</ul>
				</div>

				<div class="payment-section">
					<p class="payment-info">
						Secure payment processing through PayPal. You can pay with your PayPal account or credit card.
					</p>
					
					<button 
						class="paypal-button" 
						class:processing={isProcessingPayment}
						disabled={isProcessingPayment}
						on:click={purchaseContact}
					>
						<div class="paypal-button-content">
							{#if isProcessingPayment}
								<div class="loading-spinner"></div>
								<span>Processing Payment...</span>
							{:else}
								<svg class="paypal-logo" viewBox="0 0 24 24" fill="currentColor">
									<path d="M7.076 21.337H2.47a.641.641 0 0 1-.633-.74L4.944.901C5.026.382 5.474 0 5.998 0h7.46c2.57 0 4.578.543 5.69 1.81 1.01 1.15 1.304 2.42 1.012 4.287-.023.143-.047.288-.077.437-.983 5.05-4.349 6.797-8.647 6.797h-2.19c-.524 0-.968.382-1.05.9l-1.12 7.106zm14.146-14.42a3.35 3.35 0 0 0-.281-.419c1.155.858 1.654 2.445 1.296 4.463-.983 5.05-4.349 6.797-8.647 6.797h-2.19c-.524 0-.968.382-1.05.9l-1.12 7.106H7.076a.641.641 0 0 1-.633-.74L8.55 18.23c.082-.518.526-.9 1.05-.9h2.19c4.298 0 7.664-1.747 8.647-6.797.358-2.018-.141-3.605-1.296-4.463z"/>
								</svg>
								<span>Pay ${contactFee.price} with PayPal</span>
							{/if}
						</div>
					</button>
					
					<div class="payment-security">
						<small>
							🔒 Your payment information is secure and encrypted. 
							We never store your payment details.
						</small>
					</div>
				</div>
			{/if}
		</div>

		<!-- Safety Tips -->
		<div class="safety-section">
			<h3 class="section-title">Safety Tips</h3>
			<ul class="safety-tips">
				<li>Always meet in public places during daylight hours</li>
				<li>Bring a friend or let someone know your plans</li>
				<li>Verify the currency before completing the exchange</li>
				<li>Use NICE Traders' dispute resolution if issues arise</li>
				<li>Never share personal financial information</li>
			</ul>
		</div>
		{/if}
	</div>



	<!-- Report Modal -->
	{#if showReportModal}
		<div class="modal-overlay" role="presentation" on:click={closeReportModal} on:keydown={(e) => e.key === 'Escape' && closeReportModal()}>
			<div class="report-modal" role="dialog" tabindex="-1" on:click|stopPropagation on:keydown={() => {}}>
				<div class="modal-header">
					<h3 class="modal-title">Report Listing</h3>
					<button class="close-button" on:click={closeReportModal} aria-label="Close modal">
						<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
							<line x1="18" y1="6" x2="6" y2="18"></line>
							<line x1="6" y1="6" x2="18" y2="18"></line>
						</svg>
					</button>
				</div>

				<div class="modal-content">
					<p class="report-description">
						Help us keep the platform safe by reporting inappropriate listings.
					</p>

					<div class="form-group">
						<label for="reportReason" class="form-label">Reason for reporting:</label>
						<select 
							id="reportReason"
							bind:value={reportReason} 
							class="form-select"
						>
							<option value="">Select a reason</option>
							{#each getReportReasons() as reason}
								<option value={reason.value}>{reason.label}</option>
							{/each}
						</select>
					</div>

					<div class="form-group">
						<label for="reportDescription" class="form-label">Additional details (optional):</label>
						<textarea 
							id="reportDescription"
							bind:value={reportDescription}
							class="form-textarea"
							placeholder="Please provide any additional information that might help us review this report..."
							rows="4"
						></textarea>
					</div>

					<div class="modal-actions">
						<button class="cancel-button" on:click={closeReportModal}>
							Cancel
						</button>
						<button class="submit-button" on:click={submitReport} disabled={!reportReason}>
							Submit Report
						</button>
					</div>
				</div>
			</div>
		</div>
	{/if}
</main>

<style>
	.contact-container {
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

	.back-button, .menu-button {
		background: rgba(255, 255, 255, 0.2);
		border: none;
		color: white;
		cursor: pointer;
		padding: 0.5rem;
		border-radius: 8px;
		transition: background-color 0.2s;
	}

	.back-button:hover, .menu-button:hover {
		background: rgba(255, 255, 255, 0.3);
	}

	.page-title {
		font-size: 1.25rem;
		font-weight: 600;
		margin: 0;
	}

	.content {
		flex: 1;
		padding: 1.5rem;
		display: flex;
		flex-direction: column;
		gap: 1.5rem;
	}

	/* Listing Summary */
	.listing-summary {
		background: white;
		border-radius: 12px;
		padding: 1.5rem;
		border: 1px solid #e2e8f0;
	}

	.listing-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
	}

	.currency-display {
		display: flex;
		align-items: center;
		gap: 0.75rem;
	}

	.currency-flag {
		width: 32px;
		height: 24px;
		object-fit: cover;
		border-radius: 4px;
		border: 1px solid #e2e8f0;
	}

	.currency-amount {
		font-size: 1.5rem;
		font-weight: 600;
		color: #2d3748;
		display: block;
	}

	.currency-rate {
		font-size: 1rem;
		color: #667eea;
		font-weight: 500;
	}

	.location-info {
		text-align: right;
		display: flex;
		flex-direction: column;
		gap: 0.25rem;
	}

	.location {
		font-weight: 500;
		color: #4a5568;
		font-size: 0.95rem;
	}

	.radius {
		font-size: 0.85rem;
		color: #718096;
		background: #f7fafc;
		padding: 0.25rem 0.5rem;
		border-radius: 6px;
	}

	/* Trader Profile */
	.trader-profile {
		background: white;
		border-radius: 12px;
		padding: 1.5rem;
		border: 1px solid #e2e8f0;
	}

	.profile-header {
		display: flex;
		justify-content: space-between;
		align-items: flex-start;
		margin-bottom: 1.5rem;
	}

	.trader-name {
		font-size: 1.25rem;
		font-weight: 600;
		color: #2d3748;
		display: flex;
		align-items: center;
		gap: 0.5rem;
		margin-bottom: 0.5rem;
	}

	.verified-badge {
		background: #48bb78;
		color: white;
		border-radius: 50%;
		width: 20px;
		height: 20px;
		display: flex;
		align-items: center;
		justify-content: center;
		font-size: 12px;
		font-weight: bold;
	}

	.trader-stats {
		display: flex;
		gap: 1rem;
		font-size: 0.9rem;
		color: #718096;
	}

	.trader-status {
		text-align: right;
	}

	.last-active {
		font-size: 0.85rem;
		color: #48bb78;
		font-weight: 500;
	}

	.detail-grid {
		display: grid;
		gap: 0.75rem;
	}

	.detail-item {
		display: flex;
		justify-content: space-between;
		align-items: center;
		padding: 0.5rem 0;
		border-bottom: 1px solid #f1f5f9;
	}

	.detail-item:last-child {
		border-bottom: none;
	}

	.detail-label {
		font-weight: 500;
		color: #718096;
		font-size: 0.9rem;
	}

	.detail-value {
		color: #4a5568;
		font-size: 0.9rem;
	}

	/* Contact Status */
	.contact-status {
		background: white;
		border-radius: 12px;
		padding: 1.5rem;
		display: flex;
		align-items: center;
		gap: 1rem;
		border: 2px solid;
	}

	.contact-status.active {
		border-color: #48bb78;
		background: #f0fff4;
	}

	.contact-status.limited {
		border-color: #ed8936;
		background: #fffaf0;
	}

	.status-icon {
		font-size: 1.5rem;
	}

	.status-title {
		font-size: 1.1rem;
		font-weight: 600;
		color: #2d3748;
		margin: 0 0 0.25rem;
	}

	.status-text {
		font-size: 0.9rem;
		color: #718096;
		margin: 0;
		line-height: 1.4;
	}

	.section-title {
		font-size: 1.1rem;
		font-weight: 600;
		color: #2d3748;
		margin: 0 0 0.5rem;
	}

	.section-subtitle {
		font-size: 0.9rem;
		color: #718096;
		margin: 0 0 1.5rem;
	}

	/* Full Contact */
	.full-contact {
		background: white;
		border-radius: 12px;
		padding: 1.5rem;
		border: 1px solid #e2e8f0;
	}

	.subsection-title {
		font-size: 1rem;
		font-weight: 600;
		color: #2d3748;
		margin: 0 0 1rem;
	}

	/* Messaging Section */
	.messaging-section {
		margin-bottom: 2rem;
	}

	.message-thread {
		background: #f7fafc;
		border-radius: 8px;
		padding: 1rem;
		min-height: 150px;
		max-height: 300px;
		overflow-y: auto;
		margin-bottom: 1rem;
	}

	.no-messages {
		color: #a0aec0;
		text-align: center;
		font-style: italic;
		margin: 2rem 0;
	}

	.message-compose {
		display: flex;
		flex-direction: column;
		gap: 0.75rem;
	}

	.message-input {
		width: 100%;
		padding: 0.75rem;
		border: 1px solid #e2e8f0;
		border-radius: 8px;
		font-family: inherit;
		font-size: 0.95rem;
		resize: vertical;
	}

	.message-input:focus {
		border-color: #667eea;
		outline: none;
		box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
	}

	.send-message-button {
		align-self: flex-end;
		background: #667eea;
		color: white;
		border: none;
		padding: 0.75rem 1.5rem;
		border-radius: 8px;
		font-weight: 600;
		cursor: pointer;
		transition: background 0.2s;
	}

	.send-message-button:hover {
		background: #5a67d8;
	}

	/* Meeting Proposal Section */
	.meeting-proposal-section {
		padding-top: 1.5rem;
		border-top: 1px solid #e2e8f0;
	}

	.meeting-form {
		display: flex;
		flex-direction: column;
		gap: 1rem;
	}

	.form-input {
		width: 100%;
		padding: 0.75rem;
		border: 1px solid #e2e8f0;
		border-radius: 8px;
		font-size: 0.95rem;
	}

	.form-input:focus {
		border-color: #667eea;
		outline: none;
		box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
	}

	.propose-meeting-button {
		background: #48bb78;
		color: white;
		border: none;
		padding: 0.875rem;
		border-radius: 8px;
		font-weight: 600;
		cursor: pointer;
		transition: background 0.2s;
	}

	.propose-meeting-button:hover {
		background: #38a169;
	}

	.contact-details {
		display: flex;
		flex-direction: column;
		gap: 1rem;
	}

	.contact-item {
		display: flex;
		justify-content: space-between;
		align-items: center;
		padding: 0.75rem;
		background: #f7fafc;
		border-radius: 8px;
	}

	.contact-label {
		font-weight: 500;
		color: #4a5568;
	}

	.contact-value {
		color: #2d3748;
		font-weight: 500;
	}

	.contact-actions {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 1rem;
		margin-top: 0.5rem;
	}

	.contact-action-button {
		padding: 0.875rem;
		border: none;
		border-radius: 8px;
		font-weight: 600;
		cursor: pointer;
		font-size: 0.9rem;
		transition: transform 0.2s;
	}

	.contact-action-button:hover {
		transform: translateY(-1px);
	}

	.contact-action-button.call {
		background: #68d391;
		color: white;
	}

	.contact-action-button.message {
		background: #667eea;
		color: white;
	}

	/* Pricing Card */
	.pricing-card {
		border: 2px solid #667eea;
		border-radius: 12px;
		padding: 1.5rem;
		background: #f7fafc;
		margin-bottom: 1.5rem;
	}

	.plan-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 1rem;
	}

	.plan-name {
		font-size: 1.1rem;
		font-weight: 600;
		color: #2d3748;
		margin: 0;
	}

	.plan-price {
		font-size: 1.25rem;
		font-weight: 700;
		color: #667eea;
	}

	.plan-features {
		list-style: none;
		padding: 0;
		margin: 0;
		display: flex;
		flex-direction: column;
		gap: 0.5rem;
	}

	.plan-feature {
		font-size: 0.9rem;
		color: #4a5568;
	}



	/* Safety Section */
	.safety-section {
		background: #fffaf0;
		border: 1px solid #f6ad55;
		border-radius: 12px;
		padding: 1.5rem;
	}

	.safety-tips {
		list-style: none;
		padding: 0;
		margin: 0;
		display: flex;
		flex-direction: column;
		gap: 0.5rem;
	}

	.safety-tips li {
		font-size: 0.9rem;
		color: #744210;
		padding-left: 1.5rem;
		position: relative;
	}

	.safety-tips li::before {
		content: '⚠️';
		position: absolute;
		left: 0;
		top: 0;
	}

	/* Payment Modal */
	.modal-overlay {
		position: fixed;
		top: 0;
		left: 0;
		right: 0;
		bottom: 0;
		background: rgba(0, 0, 0, 0.5);
		display: flex;
		align-items: center;
		justify-content: center;
		z-index: 50;
		padding: 1rem;
	}



	.payment-section {
		margin-top: 1.5rem;
	}

	.payment-info {
		font-size: 0.9rem;
		color: #718096;
		margin-bottom: 1.5rem;
		text-align: center;
	}

	.paypal-button {
		width: 100%;
		background: #0070ba;
		color: white;
		border: none;
		padding: 1rem 1.5rem;
		border-radius: 8px;
		cursor: pointer;
		font-size: 1rem;
		font-weight: 600;
		transition: all 0.2s;
		margin-bottom: 1rem;
	}

	.paypal-button:hover:not(:disabled) {
		background: #005ea6;
		transform: translateY(-1px);
	}

	.paypal-button:disabled {
		opacity: 0.7;
		cursor: not-allowed;
		transform: none;
	}

	.paypal-button.processing {
		background: #005ea6;
	}

	.paypal-button-content {
		display: flex;
		align-items: center;
		justify-content: center;
		gap: 0.75rem;
	}

	.paypal-logo {
		width: 24px;
		height: 24px;
	}

	.payment-security {
		text-align: center;
		margin-top: 1rem;
	}

	.payment-security small {
		color: #718096;
		font-size: 0.8rem;
	}

	.loading-spinner {
		width: 20px;
		height: 20px;
		border: 2px solid rgba(255, 255, 255, 0.3);
		border-radius: 50%;
		border-top-color: white;
		animation: spin 1s ease-in-out infinite;
	}

	@keyframes spin {
		to { transform: rotate(360deg); }
	}

	/* Responsive adjustments */
	@media (max-width: 375px) {
		.contact-container {
			max-width: 375px;
		}
		
		.content {
			padding: 1rem;
		}
		
		.listing-header {
			flex-direction: column;
			gap: 1rem;
			align-items: flex-start;
		}
		
		.contact-actions {
			grid-template-columns: 1fr;
		}
	}

	/* Loading and Error States */
	.loading-state,
	.error-state {
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		padding: 3rem 1rem;
		text-align: center;
	}

	.loading-spinner {
		width: 40px;
		height: 40px;
		border: 4px solid #e2e8f0;
		border-top: 4px solid #667eea;
		border-radius: 50%;
		animation: spin 1s linear infinite;
		margin-bottom: 1rem;
	}

	@keyframes spin {
		0% { transform: rotate(0deg); }
		100% { transform: rotate(360deg); }
	}

	.error-message {
		color: #e53e3e;
		font-size: 1.1rem;
		margin-bottom: 1rem;
	}

	.retry-button {
		background: #667eea;
		color: white;
		border: none;
		padding: 0.75rem 1.5rem;
		border-radius: 8px;
		font-weight: 600;
		cursor: pointer;
	}

	.retry-button:hover {
		background: #5a67d8;
	}

	/* Report Modal */
	.report-modal {
		background: white;
		border-radius: 12px;
		max-width: 500px;
		width: 90%;
		max-height: 90vh;
		overflow-y: auto;
		box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
	}

	.report-description {
		color: #4a5568;
		margin-bottom: 1.5rem;
		line-height: 1.6;
	}

	.form-group {
		margin-bottom: 1.5rem;
	}

	.form-label {
		display: block;
		font-weight: 600;
		color: #2d3748;
		margin-bottom: 0.5rem;
	}

	.form-select {
		width: 100%;
		padding: 0.75rem;
		border: 1px solid #e2e8f0;
		border-radius: 8px;
		font-size: 1rem;
		background: white;
	}

	.form-select:focus {
		border-color: #667eea;
		outline: none;
		box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
	}

	.form-textarea {
		width: 100%;
		padding: 0.75rem;
		border: 1px solid #e2e8f0;
		border-radius: 8px;
		font-size: 1rem;
		font-family: inherit;
		resize: vertical;
		min-height: 100px;
	}

	.form-textarea:focus {
		border-color: #667eea;
		outline: none;
		box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
	}

	.submit-button {
		background: #e53e3e;
		color: white;
		border: none;
		padding: 1rem;
		border-radius: 8px;
		font-weight: 600;
		cursor: pointer;
	}

	.submit-button:disabled {
		background: #cbd5e0;
		cursor: not-allowed;
	}

	.submit-button:not(:disabled):hover {
		background: #c53030;
	}

	@media (max-width: 320px) {
		.contact-container {
			max-width: 320px;
		}
		
		.header {
			padding: 1rem;
		}
		
		.trader-stats {
			flex-direction: column;
			gap: 0.25rem;
		}
		

		
		.modal-actions {
			grid-template-columns: 1fr;
		}
	}
</style>