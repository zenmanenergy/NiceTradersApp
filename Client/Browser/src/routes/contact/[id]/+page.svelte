<script>
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';
	import { Session } from '../../../Session.js';
	import { handleGetContactMessages, handleSendContactMessage } from '../../dashboard/handleDashboard.js';
	import { handleProposeMeeting, handleRespondToMeeting, handleGetMeetingProposals } from '../handleMeeting.js';

	let contactId = '';
	let contactData = null;
	let messages = [];
	let newMessage = '';
	let activeTab = 'details';
	let messagesContainer;
	
	// Meeting proposal variables
	let meetingProposals = [];
	let currentMeeting = null;
	let showProposeForm = false;
	let proposedLocation = '';
	let proposedDate = '';
	let proposedTime = '';
	let proposalMessage = '';

	function scrollToBottom() {
		if (messagesContainer) {
			setTimeout(() => {
				messagesContainer.scrollTop = messagesContainer.scrollHeight;
			}, 100);
		}
	}

	onMount(async () => {
		await Session.handleSession();
		Session.GetSessionId(); // This sets Session.SessionId
		const sessionId = Session.SessionId;
		
		if (!sessionId) {
			goto('/login');
			return;
		}
		
		contactId = $page.params.id;
		
		// Get contact data from sessionStorage (passed from dashboard)
		const storedContact = sessionStorage.getItem('contactData');
		if (storedContact) {
			contactData = JSON.parse(storedContact);
			sessionStorage.removeItem('contactData');
			loadMessages();
			loadMeetingProposals();
		} else {
			goto('/dashboard');
		}
	});

	function loadMessages() {
		if (!contactData) return;
		
		const sessionId = Session.SessionId;
		if (!sessionId) {
			goto('/login');
			return;
		}
		
		handleGetContactMessages(sessionId, contactData.listing_id, (response) => {
			if (response && response.success) {
				messages = response.messages || [];
				scrollToBottom();
			}
		});
	}

	function sendMessage() {
		if (!newMessage.trim() || !contactData) return;

		const sessionId = Session.SessionId;
		if (!sessionId) {
			goto('/login');
			return;
		}

		handleSendContactMessage(sessionId, contactData.listing_id, newMessage, (response) => {
			if (response && response.success) {
				// Don't add message manually - just reload to get the complete conversation
				// This ensures proper is_from_user detection from server
				newMessage = '';
				loadMessages(); // This will auto-scroll to bottom
			}
		});
	}

	function goBack() {
		goto('/dashboard');
	}
	
	// Meeting proposal functions
	function loadMeetingProposals() {
		if (!contactData) return;
		
		const sessionId = Session.SessionId;
		if (!sessionId) {
			goto('/login');
			return;
		}
		
		handleGetMeetingProposals(sessionId, contactData.listing_id, (response) => {
			if (response && response.success) {
				meetingProposals = response.proposals || [];
				currentMeeting = response.current_meeting;
			}
		});
	}
	
	function proposeMeeting() {
		console.log('proposeMeeting called with:', { proposedLocation, proposedDate, proposedTime, contactData });
		
		if (!proposedLocation.trim() || !proposedDate || !proposedTime) {
			alert('Please fill in all required fields');
			return;
		}
		
		const sessionId = Session.SessionId;
		console.log('Session ID:', sessionId);
		
		if (!sessionId) {
			goto('/login');
			return;
		}
		
		if (!contactData || !contactData.listing_id) {
			alert('Contact data not available');
			console.error('Contact data missing:', contactData);
			return;
		}
		
		const proposedDateTime = `${proposedDate}T${proposedTime}:00`;
		console.log('Calling handleProposeMeeting with:', { sessionId, listingId: contactData.listing_id, proposedLocation, proposedDateTime, proposalMessage });
		
		handleProposeMeeting(sessionId, contactData.listing_id, proposedLocation, proposedDateTime, proposalMessage, (response) => {
			console.log('handleProposeMeeting response:', response);
			if (response && response.success) {
				// Reset form
				proposedLocation = '';
				proposedDate = '';
				proposedTime = '';
				proposalMessage = '';
				showProposeForm = false;
				
				// Reload proposals
				loadMeetingProposals();
			} else {
				alert(response?.error || 'Failed to propose meeting');
			}
		});
	}
	
	function respondToProposal(proposalId, response) {
		const sessionId = Session.SessionId;
		if (!sessionId) {
			goto('/login');
			return;
		}
		
		handleRespondToMeeting(sessionId, proposalId, response, (serverResponse) => {
			if (serverResponse && serverResponse.success) {
				// Reload proposals
				loadMeetingProposals();
			} else {
				alert(serverResponse?.error || `Failed to ${response} proposal`);
			}
		});
	}
	
	function formatDateTime(dateTimeString) {
		if (!dateTimeString) return 'Not specified';
		try {
			const date = new Date(dateTimeString);
			return date.toLocaleString();
		} catch (e) {
			return dateTimeString;
		}
	}
</script>

<svelte:head>
	<title>Contact Details - Nice Traders</title>
</svelte:head>

<div class="contact-page">
	{#if contactData}
		<!-- Header -->
		<div class="contact-header">
			<button class="back-button" on:click={goBack} aria-label="Go back">
				<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
					<polyline points="15,18 9,12 15,6"></polyline>
				</svg>
			</button>
			<div class="exchange-overview">
				<h1 class="exchange-title">
					{contactData.listing.currency}
					<span class="exchange-arrow">→</span>
					{contactData.listing.accept_currency || contactData.listing.preferred_currency}
				</h1>
				<div class="exchange-amount">${contactData.listing.amount}</div>
			</div>
		</div>

		<div class="content">
			<!-- Tab Navigation - Icon Only for Mobile -->
			<div class="tab-navigation">
				<button 
					class="tab-button {activeTab === 'details' ? 'active' : ''}" 
					on:click={() => activeTab = 'details'}
				>
					<div class="tab-icon">📋</div>
					<span class="tab-label">Details</span>
				</button>
				<button 
					class="tab-button {activeTab === 'location' ? 'active' : ''}" 
					on:click={() => activeTab = 'location'}
				>
					<div class="tab-icon">📍</div>
					<span class="tab-label">Location</span>
				</button>
				<button 
					class="tab-button {activeTab === 'messages' ? 'active' : ''}" 
					on:click={() => activeTab = 'messages'}
				>
					<div class="tab-icon">💬</div>
					<span class="tab-label">Chat ({messages.length})</span>
				</button>
			</div>
			{#if activeTab === 'details'}
				<div class="details-section">
					<h2 class="section-title">Exchange Details</h2>
					<div class="details-grid">
						<div class="detail-item">
							<label>Amount to Exchange:</label>
							<div class="detail-value">${contactData.listing.amount} {contactData.listing.currency}</div>
						</div>
						<div class="detail-item">
							<label>Receiving:</label>
							<div class="detail-value">
								{#if contactData.locked_amount}
									${contactData.locked_amount} {contactData.to_currency || contactData.listing.accept_currency || contactData.listing.preferred_currency}
								{:else}
									Exchange rate pending calculation
								{/if}
							</div>
						</div>
						<div class="detail-item">
							<label>Exchange Rate:</label>
							<div class="detail-value">
								{#if contactData.exchange_rate}
									{contactData.exchange_rate} {contactData.from_currency || contactData.listing.currency} per {contactData.to_currency || contactData.listing.accept_currency || contactData.listing.preferred_currency}
								{:else}
									Exchange rate pending calculation
								{/if}
							</div>
						</div>
						<div class="detail-item">
							<label>Meeting Preference:</label>
							<div class="detail-value">{contactData.listing.meeting_preference || 'Not specified'}</div>
						</div>
						<div class="detail-item">
							<label>General Location:</label>
							<div class="detail-value">{contactData.listing.location}</div>
						</div>
						<div class="detail-item">
							<label>Contact Purchased:</label>
							<div class="detail-value">
								{#if contactData.purchased_at}
									{new Date(contactData.purchased_at).toLocaleDateString()}
								{:else}
									Not specified
								{/if}
							</div>
						</div>
					</div>
				</div>

				<div class="trader-section">
					<h2 class="section-title">Trader Information</h2>
					<div class="trader-name">
						{contactData.seller?.name || contactData.other_user?.first_name + ' ' + contactData.other_user?.last_name}
					</div>
					<div class="trader-rating">
						{#each Array(5) as _, i}
							<span class="star {i < Math.floor(contactData.other_user?.rating || 0) ? 'filled' : ''}">★</span>
						{/each}
						<span class="rating-text">({contactData.other_user?.total_trades || 0} trades)</span>
					</div>
				</div>
			{:else if activeTab === 'location'}
				<div class="location-section">
					<h2 class="section-title">Meeting Coordination</h2>
					
					<!-- Current Meeting (if agreed) -->
					{#if currentMeeting}
						<div class="current-meeting">
							<h3 class="meeting-status agreed">✅ Meeting Agreed</h3>
							<div class="meeting-details">
								<div class="meeting-detail">
									<strong>📍 Location:</strong> {currentMeeting.location}
								</div>
								<div class="meeting-detail">
									<strong>🕒 Time:</strong> {formatDateTime(currentMeeting.time)}
								</div>
								{#if currentMeeting.message}
									<div class="meeting-detail">
										<strong>💬 Note:</strong> {currentMeeting.message}
									</div>
								{/if}
								<div class="meeting-detail">
									<strong>📅 Agreed:</strong> {formatDateTime(currentMeeting.agreed_at)}
								</div>
							</div>
						</div>
					{:else}
						<div class="meeting-status-pending">
							<span class="status-pending">⏳ No meeting scheduled yet</span>
						</div>
					{/if}

					<!-- Propose Meeting Button -->
					{#if !currentMeeting}
						<div class="propose-meeting-actions">
							<button class="propose-btn" on:click={() => showProposeForm = !showProposeForm}>
								📅 Propose Meeting Time & Location
							</button>
						</div>

						<!-- Propose Meeting Form -->
						{#if showProposeForm}
							<div class="propose-form">
								<h4>Propose Meeting Details</h4>
								<div class="form-group">
									<label for="proposed-location">Meeting Location *</label>
									<input 
										id="proposed-location"
										type="text" 
										bind:value={proposedLocation} 
										placeholder="e.g., Starbucks on 5th Street, Central Park, etc."
										class="form-input"
									/>
								</div>
								<div class="form-row">
									<div class="form-group">
										<label for="proposed-date">Date *</label>
										<input 
											id="proposed-date"
											type="date" 
											bind:value={proposedDate}
											min={new Date().toISOString().split('T')[0]}
											class="form-input"
										/>
									</div>
									<div class="form-group">
										<label for="proposed-time">Time *</label>
										<input 
											id="proposed-time"
											type="time" 
											bind:value={proposedTime}
											class="form-input"
										/>
									</div>
								</div>
								<div class="form-group">
									<label for="proposal-message">Optional Message</label>
									<textarea 
										id="proposal-message"
										bind:value={proposalMessage} 
										placeholder="Any additional details or preferences..."
										class="form-textarea"
									></textarea>
								</div>
								<div class="form-actions">
									<button class="btn-secondary" on:click={() => showProposeForm = false}>Cancel</button>
									<button class="btn-primary" on:click={proposeMeeting}>Send Proposal</button>
								</div>
							</div>
						{/if}
					{/if}

					<!-- Meeting Proposals History -->
					{#if meetingProposals.length > 0}
						<div class="proposals-section">
							<h4>Meeting Proposals</h4>
							<div class="proposals-list">
								{#each meetingProposals as proposal}
									<div class="proposal-card {proposal.status}">
										<div class="proposal-header">
											<div class="proposal-from">
												{#if proposal.is_from_me}
													<span class="proposal-label">Your proposal</span>
												{:else}
													<span class="proposal-label">From {proposal.proposer.first_name}</span>
												{/if}
											</div>
											<div class="proposal-status status-{proposal.status}">
												{#if proposal.status === 'pending'}⏳ Pending
												{:else if proposal.status === 'accepted'}✅ Accepted
												{:else if proposal.status === 'rejected'}❌ Rejected
												{:else if proposal.status === 'expired'}⏰ Expired
												{/if}
											</div>
										</div>
										<div class="proposal-details">
											<div class="proposal-location">📍 {proposal.proposed_location}</div>
											<div class="proposal-time">🕒 {formatDateTime(proposal.proposed_time)}</div>
											{#if proposal.message}
												<div class="proposal-message">💬 {proposal.message}</div>
											{/if}
										</div>
										{#if !proposal.is_from_me && proposal.status === 'pending'}
											<div class="proposal-actions">
												<button class="btn-accept" on:click={() => respondToProposal(proposal.proposal_id, 'accepted')}>
													✅ Accept
												</button>
												<button class="btn-reject" on:click={() => respondToProposal(proposal.proposal_id, 'rejected')}>
													❌ Reject
												</button>
											</div>
										{/if}
									</div>
								{/each}
							</div>
						</div>
					{/if}

					<!-- General Area Info -->
					<div class="general-location">
						<h4>General Area</h4>
						<p>📍 {contactData.listing.location}</p>
						<p class="location-note">Specific meeting locations should be agreed upon through proposals above.</p>
					</div>
				</div>
			{:else if activeTab === 'messages'}
				<div class="messages-section">
					<h2 class="section-title">Messages</h2>
					<div class="messages-area" bind:this={messagesContainer}>
						{#if messages.length > 0}
							{#each messages as message}
								<div class="message {message.is_from_user ? 'sent' : 'received'}">
									{#if !message.is_from_user}
										<div class="avatar">
											{contactData.type === 'buyer' ? contactData.seller?.name?.charAt(0) || 'S' : contactData.buyer?.name?.charAt(0) || 'B'}
										</div>
									{/if}
									<div class="message-content">
										{message.message_text}
										<div class="message-time">
											{new Date(message.sent_at).toLocaleString()}
										</div>
									</div>
									{#if message.is_from_user}
										<div class="avatar">
											You
										</div>
									{/if}
								</div>
							{/each}
						{:else}
							<div class="no-messages">
								<p>No messages yet. Start the conversation!</p>
							</div>
						{/if}
					</div>
				</div>

				<!-- Fixed input at bottom -->
				<div class="message-input-container">
					<input
						class="message-input"
						type="text"
						bind:value={newMessage}
						placeholder="Type your message..."
						on:keydown={(e) => e.key === 'Enter' && sendMessage()}
					/>
					<button class="send-button" on:click={sendMessage} disabled={!newMessage.trim()}>
						Send
					</button>
				</div>
			{/if}
		</div>
	{:else}
		<div class="loading">
			<p>Loading contact details...</p>
		</div>
	{/if}
</div>

<style>
	/* Exact same form factor as dashboard - iPhone width */
	.contact-page {
		max-width: 414px;
		margin: 0 auto;
		min-height: 100vh;
		background: #f8fafc;
		display: flex;
		flex-direction: column;
		box-shadow: 0 0 20px rgba(0, 0, 0, 0.1);
		font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;
	}

	.contact-header {
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		color: white;
		padding: 1rem 1.5rem;
		display: flex;
		align-items: center;
		justify-content: space-between;
		min-height: 60px;
	}

	.back-button {
		background: rgba(255, 255, 255, 0.2);
		color: white;
		border: none;
		padding: 0.5rem 1rem;
		border-radius: 8px;
		cursor: pointer;
		font-size: 0.875rem;
		font-weight: 500;
		display: flex;
		align-items: center;
		gap: 0.5rem;
		align-self: flex-start;
	}

	.back-button:hover {
		background: #5a6268;
	}

	.exchange-overview {
		text-align: right;
		flex: 1;
	}

	.exchange-title {
		font-size: 1.8rem;
		font-weight: 700;
		color: white;
		margin: 0 0 0.5rem 0;
		display: flex;
		align-items: center;
		gap: 0.5rem;
	}

	.exchange-arrow {
		color: white;
		font-size: 1.5rem;
	}

	.exchange-amount {
		font-size: 1.4rem;
		font-weight: 600;
		color: #FFD700;
	}

	.content {
		flex: 1;
		padding: 1.5rem 1.5rem 5rem;
		overflow-y: auto;
	}

	/* Tab Navigation matching dashboard style */
	.tab-navigation {
		display: flex;
		gap: 1rem;
		margin-bottom: 2rem;
	}

	.tab-button {
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
		background: white;
		color: #4a5568;
		border: 2px solid #e2e8f0;
	}

	.tab-button:hover {
		transform: translateY(-2px);
	}

	.tab-button.active {
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		color: white;
		box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
		border: 2px solid transparent;
	}

	.tab-button.active:hover {
		box-shadow: 0 8px 25px rgba(102, 126, 234, 0.4);
	}

	.tab-icon {
		font-size: 1.5rem;
	}

	.tab-label {
		font-size: 0.75rem;
		font-weight: 500;
	}

	/* Details Section */
	.details-section {
		background: white;
		border-radius: 16px;
		padding: 1.5rem;
		margin-bottom: 2rem;
		box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
	}

	/* Messages Section - scrollable chat area */
	.messages-section {
		background: transparent !important;
		padding: 0 !important;
		margin: 0 -1.5rem 0 -1.5rem;
		border-radius: 0 !important;
		box-shadow: none !important;
		border: none !important;
		display: flex;
		flex-direction: column;
		height: calc(100vh - 160px); /* Account for header and input */
		overflow: hidden;
	}

	.messages-section .section-title {
		padding: 0 1.5rem 1rem 1.5rem;
		flex-shrink: 0;
	}

	.messages-area {
		flex: 1;
		overflow-y: auto;
		padding-bottom: 1rem;
		scroll-behavior: smooth;
	}

	.section-title {
		font-size: 1.2rem;
		font-weight: 600;
		color: #2d3748;
		margin: 0 0 1rem;
	}

	.details-grid {
		display: flex;
		flex-direction: column;
		gap: 1rem;
	}

	.detail-item {
		display: flex;
		justify-content: space-between;
		align-items: center;
		padding: 0.75rem 0;
		border-bottom: 1px solid #e2e8f0;
	}

	.detail-item:last-child {
		border-bottom: none;
	}

	.detail-item label {
		font-size: 0.9rem;
		color: #718096;
		font-weight: 500;
	}

	.detail-value {
		font-size: 0.9rem;
		color: #2d3748;
		font-weight: 600;
	}

	.trader-section {
		background: white;
		border-radius: 16px;
		padding: 1.5rem;
		margin-bottom: 2rem;
		box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
	}

	.trader-name {
		font-size: 1.1rem;
		font-weight: 600;
		color: #2d3748;
		margin-bottom: 0.5rem;
	}

	.trader-rating {
		display: flex;
		align-items: center;
		gap: 0.5rem;
	}

	.star {
		color: #e2e8f0;
		font-size: 1rem;
	}

	.star.filled {
		color: #fbbf24;
	}

	.rating-text {
		color: #718096;
		font-size: 0.875rem;
	}

	/* Location Section */
	.location-section {
		background: white;
		border-radius: 16px;
		padding: 1.5rem;
		margin-bottom: 2rem;
		box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
	}

	.status-pending {
		color: #f59e0b;
		font-weight: 600;
	}

	/* Meeting Coordination Styles */
	.current-meeting {
		background: #f0fff4;
		border: 2px solid #68d391;
		border-radius: 12px;
		padding: 1.5rem;
		margin-bottom: 1.5rem;
	}

	.meeting-status.agreed {
		color: #38a169;
		font-size: 1.1rem;
		font-weight: 600;
		margin-bottom: 1rem;
	}

	.meeting-details {
		display: flex;
		flex-direction: column;
		gap: 0.75rem;
	}

	.meeting-detail {
		font-size: 0.95rem;
		line-height: 1.4;
	}

	.meeting-status-pending {
		text-align: center;
		padding: 1rem;
		margin-bottom: 1.5rem;
	}

	.propose-meeting-actions {
		text-align: center;
		margin-bottom: 1.5rem;
	}

	.propose-btn {
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		color: white;
		border: none;
		border-radius: 12px;
		padding: 1rem 1.5rem;
		font-size: 1rem;
		font-weight: 600;
		cursor: pointer;
		transition: transform 0.2s, box-shadow 0.2s;
	}

	.propose-btn:hover {
		transform: translateY(-2px);
		box-shadow: 0 4px 12px rgba(102, 126, 234, 0.3);
	}

	.propose-form {
		background: white;
		border: 2px solid #e2e8f0;
		border-radius: 12px;
		padding: 1.5rem;
		margin-bottom: 1.5rem;
	}

	.propose-form h4 {
		margin: 0 0 1rem 0;
		color: #2d3748;
		font-size: 1.1rem;
	}

	.form-group {
		margin-bottom: 1rem;
	}

	.form-row {
		display: flex;
		gap: 1rem;
	}

	.form-row .form-group {
		flex: 1;
	}

	.form-group label {
		display: block;
		margin-bottom: 0.5rem;
		font-weight: 600;
		color: #4a5568;
		font-size: 0.9rem;
	}

	.form-input, .form-textarea {
		width: 100%;
		padding: 0.75rem;
		border: 2px solid #e2e8f0;
		border-radius: 8px;
		font-size: 1rem;
		transition: border-color 0.2s;
		box-sizing: border-box;
	}

	.form-input:focus, .form-textarea:focus {
		outline: none;
		border-color: #667eea;
	}

	.form-textarea {
		resize: vertical;
		min-height: 80px;
	}

	.form-actions {
		display: flex;
		gap: 1rem;
		justify-content: flex-end;
		margin-top: 1.5rem;
	}

	.btn-primary, .btn-secondary, .btn-accept, .btn-reject {
		padding: 0.75rem 1.5rem;
		border-radius: 8px;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.2s;
		border: none;
		font-size: 0.9rem;
	}

	.btn-primary {
		background: #667eea;
		color: white;
	}

	.btn-primary:hover {
		background: #5a67d8;
	}

	.btn-secondary {
		background: #e2e8f0;
		color: #4a5568;
	}

	.btn-secondary:hover {
		background: #cbd5e0;
	}

	.proposals-section {
		margin-top: 2rem;
	}

	.proposals-section h4 {
		margin: 0 0 1rem 0;
		color: #2d3748;
		font-size: 1.1rem;
	}

	.proposals-list {
		display: flex;
		flex-direction: column;
		gap: 1rem;
	}

	.proposal-card {
		background: white;
		border: 2px solid #e2e8f0;
		border-radius: 12px;
		padding: 1rem;
		transition: border-color 0.2s;
	}

	.proposal-card.accepted {
		border-color: #68d391;
		background: #f0fff4;
	}

	.proposal-card.rejected {
		border-color: #fc8181;
		background: #fef5e7;
	}

	.proposal-card.expired {
		border-color: #a0aec0;
		background: #f7fafc;
		opacity: 0.8;
	}

	.proposal-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 0.75rem;
	}

	.proposal-label {
		font-weight: 600;
		color: #4a5568;
		font-size: 0.9rem;
	}

	.proposal-status {
		font-weight: 600;
		font-size: 0.85rem;
		padding: 0.25rem 0.75rem;
		border-radius: 20px;
	}

	.status-pending {
		background: #fef5e7;
		color: #d69e2e;
	}

	.status-accepted {
		background: #f0fff4;
		color: #38a169;
	}

	.status-rejected {
		background: #fed7d7;
		color: #e53e3e;
	}

	.status-expired {
		background: #f7fafc;
		color: #a0aec0;
	}

	.proposal-details {
		display: flex;
		flex-direction: column;
		gap: 0.5rem;
		margin-bottom: 1rem;
		font-size: 0.9rem;
	}

	.proposal-actions {
		display: flex;
		gap: 0.75rem;
		justify-content: flex-end;
	}

	.btn-accept {
		background: #48bb78;
		color: white;
		padding: 0.5rem 1rem;
		font-size: 0.85rem;
	}

	.btn-accept:hover {
		background: #38a169;
	}

	.btn-reject {
		background: #f56565;
		color: white;
		padding: 0.5rem 1rem;
		font-size: 0.85rem;
	}

	.btn-reject:hover {
		background: #e53e3e;
	}

	.general-location {
		background: #f8fafc;
		border: 2px dashed #e2e8f0;
		border-radius: 12px;
		padding: 1.5rem;
		margin-top: 2rem;
	}

	.general-location h4 {
		margin: 0 0 0.5rem 0;
		color: #2d3748;
		font-size: 1rem;
	}

	.general-location p {
		margin: 0.5rem 0;
		color: #4a5568;
	}

	.location-note {
		font-size: 0.85rem;
		color: #718096;
		font-style: italic;
	}

	/* Messages Section */
	.messages-section {
		background: white;
		border-radius: 16px;
		padding: 1.5rem;
		margin-bottom: 2rem;
		box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
		height: 400px;
		display: flex;
		flex-direction: column;
	}

	.message {
		display: flex;
		margin-bottom: 0.75rem;
		padding: 0 1rem;
		align-items: flex-end;
		gap: 0.5rem;
	}

	.message.sent {
		justify-content: flex-end;
	}

	.message.received {
		justify-content: flex-start;
	}

	.avatar {
		width: 32px;
		height: 32px;
		border-radius: 50%;
		background: #667eea;
		color: white;
		display: flex;
		align-items: center;
		justify-content: center;
		font-size: 0.75rem;
		font-weight: 600;
		flex-shrink: 0;
		margin-bottom: 2px;
	}

	.message.sent .avatar {
		background: #34d399;
	}

	.message-content {
		max-width: 75%;
		padding: 0.75rem 1rem;
		border-radius: 18px;
		position: relative;
		font-size: 0.95rem;
		word-wrap: break-word;
		line-height: 1.4;
	}

	.message.sent .message-content {
		background: #007AFF;
		color: white;
		border-bottom-right-radius: 8px;
	}

	.message.received .message-content {
		background: #E5E5EA;
		color: #000000;
		border-bottom-left-radius: 8px;
	}

	.message-time {
		font-size: 0.65rem;
		opacity: 0.6;
		display: block;
		margin-top: 0.25rem;
		font-weight: 400;
	}

	.message.sent .message-time {
		color: rgba(255, 255, 255, 0.8);
	}

	.message.received .message-time {
		color: rgba(0, 0, 0, 0.5);
	}

	/* Fixed input at bottom within mobile container */
	.message-input-container {
		position: fixed;
		bottom: 0;
		left: 50%;
		transform: translateX(-50%);
		width: 414px;
		max-width: calc(100vw - 40px);
		background: white;
		border-top: 1px solid #e2e8f0;
		padding: 1rem 1rem;
		display: flex;
		gap: 0.5rem;
		align-items: center;
		z-index: 100;
		box-shadow: 0 -2px 10px rgba(0, 0, 0, 0.1);
		box-sizing: border-box;
	}

	.no-messages {
		text-align: center;
		color: #718096;
		padding: 2rem;
	}

	.message-input {
		flex: 1;
		border: 1px solid #e2e8f0;
		border-radius: 20px;
		padding: 0.75rem 1rem;
		font-size: 1rem;
		background: #f8fafc;
		color: #2d3748;
		outline: none;
	}

	.message-input:focus {
		outline: none;
		border-color: #667eea;
	}

	.send-button {
		background: #007AFF;
		color: white;
		border: none;
		border-radius: 20px;
		padding: 0.75rem 1.5rem;
		font-weight: 600;
		cursor: pointer;
		transition: background-color 0.2s;
		min-width: 70px;
	}

	.send-button:hover:not(:disabled) {
		background: #5a67d8;
	}

	.send-button:disabled {
		background: #a0aec0;
		cursor: not-allowed;
	}

	.loading {
		text-align: center;
		padding: 2rem;
		color: #718096;
	}
</style>