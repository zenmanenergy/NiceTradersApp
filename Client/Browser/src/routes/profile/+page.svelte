<script>
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';
	import { Session } from '../../Session.js';
	import { handleGetProfile, handleUpdateProfile, handleGetExchangeHistory, handleUpdateSettings, handleDeleteAccount } from './handleProfile.js';
	
	// Mock user data (would come from authentication/API in real app)
	let user = {
		name: 'John Doe',
		email: 'john.doe@email.com',
		phone: '+1 (555) 123-4567',
		joinDate: 'October 15, 2025',
		rating: 4.8,
		totalExchanges: 12,
		completedExchanges: 11,
		verificationStatus: 'verified',
		location: 'San Francisco, CA',
		bio: 'Frequent traveler who loves helping others with currency exchanges. Always meet in safe public places!'
	};
	
	// Mock exchange history
	let exchangeHistory = [
		{
			id: 1,
			date: '2025-11-10',
			currency: 'EUR',
			amount: 250,
			partner: 'Sarah Martinez',
			rating: 5,
			type: 'sold',
			status: 'completed'
		},
		{
			id: 2,
			date: '2025-11-05',
			currency: 'GBP',
			amount: 180,
			partner: 'Mike Johnson',
			rating: 5,
			type: 'bought',
			status: 'completed'
		},
		{
			id: 3,
			date: '2025-10-28',
			currency: 'JPY',
			amount: 15000,
			partner: 'Lisa Chen',
			rating: 4,
			type: 'sold',
			status: 'completed'
		},
		{
			id: 4,
			date: '2025-10-20',
			currency: 'CAD',
			amount: 200,
			partner: 'David Wilson',
			rating: 5,
			type: 'bought',
			status: 'completed'
		}
	];
	
	// Settings
	let settings = {
		notifications: {
			newMessages: true,
			exchangeUpdates: true,
			marketingEmails: false,
			pushNotifications: true
		},
		privacy: {
			showLocation: true,
			showExchangeHistory: false,
			allowDirectMessages: true
		},
		preferences: {
			theme: 'light',
			language: 'English',
			currency: 'USD'
		}
	};
	
	let isEditing = false;
	let editedUser = { ...user };
	
	function goBack() {
		goto('/dashboard');
	}
	
	function toggleEdit() {
		if (isEditing) {
			// Save changes via API
			const sessionId = Cookies.get('SessionId');
			if (sessionId) {
				handleUpdateProfile(
					sessionId,
					editedUser.name,
					editedUser.email,
					editedUser.phone,
					editedUser.location,
					editedUser.bio,
					(result) => {
						if (result && result.success) {
							user = { ...editedUser };
							console.log('Profile updated successfully');
						} else {
							console.error('Failed to update profile:', result?.error);
						}
					}
				);
			}
		} else {
			// Start editing
			editedUser = { ...user };
		}
		isEditing = !isEditing;
	}
	
	function cancelEdit() {
		editedUser = { ...user };
		isEditing = false;
	}
	
	function handleSettingChange(category, setting) {
		settings[category][setting] = !settings[category][setting];
		
		// Save settings via API
		const sessionId = Cookies.get('SessionId');
		if (sessionId) {
			handleUpdateSettings(
				sessionId,
				JSON.stringify(settings),
				(result) => {
					if (result && result.success) {
						console.log('Settings updated successfully');
					} else {
						console.error('Failed to update settings:', result?.error);
					}
				}
			);
		}
	}
	
	function handleLogout() {
		// Clear authentication cookies
		Cookies.remove("SessionId");
		Cookies.remove("UserType");
		// Redirect to login page
		goto('/login');
	}
	
	function deleteAccount() {
		const confirmed = confirm('Are you sure you want to delete your account? This action cannot be undone.');
		if (confirmed) {
			const sessionId = Cookies.get('SessionId');
			if (sessionId) {
				handleDeleteAccount(
					sessionId,
					(result) => {
						if (result && result.success) {
							// Clear cookies and redirect to home
							Cookies.remove('SessionId');
							Cookies.remove('UserType');
							alert('Account deleted successfully');
							goto('/');
						} else {
							alert('Failed to delete account: ' + (result?.error || 'Unknown error'));
						}
					}
				);
			}
		}
	}
	
	function viewExchange(exchangeId) {
		goto(`/exchange/${exchangeId}`);
	}
	
	onMount(async () => {
		await Session.handleSession();
		Session.GetSessionId(); // This sets Session.SessionId
		const sessionId = Session.SessionId;
		
		if (!sessionId) {
			goto('/login');
			return;
		}
		
		// Load profile data
		handleGetProfile(sessionId, (result) => {
			if (result && result.success && result.profile) {
				user = { ...user, ...result.profile };
				console.log('Profile loaded:', user.name);
			} else {
				console.error('Failed to load profile:', result?.error);
			}
		});
		
		// Load exchange history
		handleGetExchangeHistory(sessionId, (result) => {
			if (result && result.success && result.exchanges) {
				exchangeHistory = result.exchanges;
				console.log('Exchange history loaded:', exchangeHistory.length, 'exchanges');
			} else {
				console.error('Failed to load exchange history:', result?.error);
			}
		});
	});
</script>

<svelte:head>
	<title>Profile - NICE Traders</title>
	<meta name="description" content="Manage your NICE Traders profile and settings" />
</svelte:head>

<main class="profile-container">
	<div class="header">
		<button class="back-button" on:click={goBack}>
			<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
				<polyline points="15,18 9,12 15,6"></polyline>
			</svg>
		</button>
		<h1 class="page-title">Profile</h1>
		<button class="edit-button" on:click={toggleEdit}>
			{#if isEditing}
				<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
					<polyline points="20,6 9,17 4,12"></polyline>
				</svg>
			{:else}
				<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
					<path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
					<path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
				</svg>
			{/if}
		</button>
	</div>

	<div class="content">
		<!-- User Profile Section -->
		<section class="user-profile">
			<div class="avatar-section">
				<div class="avatar large">
					{user.name.split(' ').map(n => n[0]).join('')}
				</div>
				<div class="verification-badge">
					{#if user.verificationStatus === 'verified'}
						<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
							<polyline points="20,6 9,17 4,12"></polyline>
						</svg>
					{/if}
				</div>
			</div>

			<div class="user-info">
				{#if isEditing}
					<input 
						type="text" 
						bind:value={editedUser.name} 
						class="edit-input name-input"
						placeholder="Full Name"
					/>
					<textarea 
						bind:value={editedUser.bio} 
						class="edit-textarea"
						placeholder="Tell others about yourself..."
						rows="3"
					></textarea>
					<input 
						type="text" 
						bind:value={editedUser.location} 
						class="edit-input"
						placeholder="Location"
					/>
					<div class="edit-actions">
						<button class="save-button" on:click={toggleEdit}>Save Changes</button>
						<button class="cancel-button" on:click={cancelEdit}>Cancel</button>
					</div>
				{:else}
					<h2 class="user-name">{user.name}</h2>
					<p class="user-bio">{user.bio}</p>
					<div class="user-details">
						<div class="detail-item">
							<span class="detail-icon">📍</span>
							<span class="detail-text">{user.location}</span>
						</div>
						<div class="detail-item">
							<span class="detail-icon">📅</span>
							<span class="detail-text">Member since {user.joinDate}</span>
						</div>
					</div>
				{/if}
			</div>
		</section>

		<!-- Stats Section -->
		<section class="stats-section">
			<h3 class="section-title">Exchange Stats</h3>
			<div class="stats-grid">
				<div class="stat-card">
					<div class="stat-number">{user.rating}</div>
					<div class="stat-label">Rating</div>
					<div class="stat-stars">
						{#each Array(5) as _, i}
							<span class="star {i < Math.floor(user.rating) ? 'filled' : ''}">⭐</span>
						{/each}
					</div>
				</div>
				<div class="stat-card">
					<div class="stat-number">{user.totalExchanges}</div>
					<div class="stat-label">Total Exchanges</div>
				</div>
				<div class="stat-card">
					<div class="stat-number">{user.totalExchanges > 0 ? Math.round((user.completedExchanges / user.totalExchanges) * 100) : 0}%</div>
					<div class="stat-label">Success Rate</div>
				</div>
			</div>
		</section>

		<!-- Exchange History Button -->
		<section class="history-section">
			<button class="view-history-btn" on:click={() => goto('/exchange-history')}>
				<div class="btn-icon">📊</div>
				<div class="btn-content">
					<span class="btn-title">View Exchange History</span>
					<span class="btn-subtitle">See all your past exchanges</span>
				</div>
				<div class="btn-arrow">
					<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
						<polyline points="9,18 15,12 9,6"></polyline>
					</svg>
				</div>
			</button>
		</section>

		<!-- Contact Info -->
		<section class="contact-section">
			<h3 class="section-title">Contact Information</h3>
			<div class="contact-info">
				{#if isEditing}
					<div class="contact-item">
						<span class="contact-label">Email</span>
						<input 
							type="email" 
							bind:value={editedUser.email} 
							class="edit-input"
							placeholder="Email address"
						/>
					</div>
					<div class="contact-item">
						<span class="contact-label">Phone</span>
						<input 
							type="tel" 
							bind:value={editedUser.phone} 
							class="edit-input"
							placeholder="Phone number"
						/>
					</div>
				{:else}
					<div class="contact-item">
						<span class="contact-label">Email</span>
						<span class="contact-value">{user.email}</span>
					</div>
					<div class="contact-item">
						<span class="contact-label">Phone</span>
						<span class="contact-value">{user.phone}</span>
					</div>
				{/if}
			</div>
		</section>

		<!-- Settings Section -->
		<section class="settings-section">
			<h3 class="section-title">Settings</h3>
			
			<div class="settings-group">
				<h4 class="settings-group-title">Notifications</h4>
				<div class="setting-item">
					<span class="setting-label">New Messages</span>
					<label class="toggle">
						<input 
							type="checkbox" 
							bind:checked={settings.notifications.newMessages}
							on:change={() => handleSettingChange('notifications', 'newMessages')}
						/>
						<span class="toggle-slider"></span>
					</label>
				</div>
				<div class="setting-item">
					<span class="setting-label">Exchange Updates</span>
					<label class="toggle">
						<input 
							type="checkbox" 
							bind:checked={settings.notifications.exchangeUpdates}
							on:change={() => handleSettingChange('notifications', 'exchangeUpdates')}
						/>
						<span class="toggle-slider"></span>
					</label>
				</div>
				<div class="setting-item">
					<span class="setting-label">Push Notifications</span>
					<label class="toggle">
						<input 
							type="checkbox" 
							bind:checked={settings.notifications.pushNotifications}
							on:change={() => handleSettingChange('notifications', 'pushNotifications')}
						/>
						<span class="toggle-slider"></span>
					</label>
				</div>
			</div>

			<div class="settings-group">
				<h4 class="settings-group-title">Privacy</h4>
				<div class="setting-item">
					<span class="setting-label">Show Location</span>
					<label class="toggle">
						<input 
							type="checkbox" 
							bind:checked={settings.privacy.showLocation}
							on:change={() => handleSettingChange('privacy', 'showLocation')}
						/>
						<span class="toggle-slider"></span>
					</label>
				</div>
				<div class="setting-item">
					<span class="setting-label">Allow Direct Messages</span>
					<label class="toggle">
						<input 
							type="checkbox" 
							bind:checked={settings.privacy.allowDirectMessages}
							on:change={() => handleSettingChange('privacy', 'allowDirectMessages')}
						/>
						<span class="toggle-slider"></span>
					</label>
				</div>
			</div>
		</section>

		<!-- Exchange History -->
		<section class="history-section">
			<div class="section-header">
				<h3 class="section-title">Recent Exchanges</h3>
				<button class="view-all-link" on:click={() => goto('/exchange-history')}>View All</button>
			</div>
			
			<div class="history-list">
				{#each exchangeHistory.slice(0, 3) as exchange}
					<div class="history-item" on:click={() => viewExchange(exchange.id)}>
						<div class="history-info">
							<div class="history-header">
								<span class="currency-badge">{exchange.currency}</span>
								<span class="exchange-type {exchange.type}">{exchange.type}</span>
							</div>
							<div class="history-amount">${exchange.amount}</div>
							<div class="history-details">
								<span class="partner-name">{exchange.partner}</span>
								<span class="exchange-date">{new Date(exchange.date).toLocaleDateString()}</span>
							</div>
							<div class="history-rating">
								{#each Array(5) as _, i}
									<span class="star {i < exchange.rating ? 'filled' : ''}">⭐</span>
								{/each}
							</div>
						</div>
						<div class="history-arrow">
							<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
								<polyline points="9,18 15,12 9,6"></polyline>
							</svg>
						</div>
					</div>
				{/each}
			</div>
		</section>

		<!-- Account Actions -->
		<section class="account-actions">
			<button class="action-button logout" on:click={handleLogout}>
				<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
					<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path>
					<polyline points="16,17 21,12 16,7"></polyline>
					<line x1="21" y1="12" x2="9" y2="12"></line>
				</svg>
				Logout
			</button>
			<button class="action-button delete" on:click={deleteAccount}>
				<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
					<polyline points="3,6 5,6 21,6"></polyline>
					<path d="M19,6v14a2 2 0 0 1-2,2H7a2 2 0 0 1-2-2V6m3,0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2,2v2"></path>
				</svg>
				Delete Account
			</button>
		</section>
	</div>
</main>

<style>
	.profile-container {
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

	.back-button, .edit-button {
		background: rgba(255, 255, 255, 0.2);
		border: none;
		color: white;
		cursor: pointer;
		padding: 0.5rem;
		border-radius: 8px;
		transition: background-color 0.2s;
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.back-button:hover, .edit-button:hover {
		background: rgba(255, 255, 255, 0.3);
	}

	.page-title {
		font-size: 1.25rem;
		font-weight: 600;
		margin: 0;
	}

	.content {
		flex: 1;
		padding: 0 1.5rem 2rem;
		overflow-y: auto;
	}

	/* User Profile Section */
	.user-profile {
		background: white;
		margin: -2rem 0 2rem;
		padding: 2rem 1.5rem 1.5rem;
		border-radius: 0 0 20px 20px;
		text-align: center;
		position: relative;
	}

	.avatar-section {
		position: relative;
		display: inline-block;
		margin-bottom: 1rem;
	}

	.avatar.large {
		width: 80px;
		height: 80px;
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		color: white;
		border-radius: 50%;
		display: flex;
		align-items: center;
		justify-content: center;
		font-weight: 600;
		font-size: 1.8rem;
		border: 4px solid white;
		box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
	}

	.verification-badge {
		position: absolute;
		bottom: 0;
		right: 0;
		background: #48bb78;
		color: white;
		width: 28px;
		height: 28px;
		border-radius: 50%;
		display: flex;
		align-items: center;
		justify-content: center;
		border: 3px solid white;
	}

	.user-name {
		font-size: 1.5rem;
		font-weight: 600;
		color: #2d3748;
		margin: 0 0 0.5rem;
	}

	.user-bio {
		color: #718096;
		line-height: 1.5;
		margin: 0 0 1rem;
		font-size: 0.95rem;
	}

	.user-details {
		display: flex;
		justify-content: center;
		gap: 1.5rem;
		flex-wrap: wrap;
	}

	.detail-item {
		display: flex;
		align-items: center;
		gap: 0.5rem;
		font-size: 0.9rem;
		color: #718096;
	}

	/* Edit Mode */
	.edit-input {
		width: 100%;
		padding: 0.75rem;
		border: 2px solid #e2e8f0;
		border-radius: 8px;
		font-size: 1rem;
		margin-bottom: 1rem;
		box-sizing: border-box;
	}

	.name-input {
		font-size: 1.2rem;
		font-weight: 600;
		text-align: center;
	}

	.edit-textarea {
		width: 100%;
		padding: 0.75rem;
		border: 2px solid #e2e8f0;
		border-radius: 8px;
		font-size: 0.95rem;
		margin-bottom: 1rem;
		resize: vertical;
		min-height: 80px;
		box-sizing: border-box;
		font-family: inherit;
	}

	.edit-actions {
		display: flex;
		gap: 1rem;
		margin-top: 1rem;
	}

	.save-button {
		flex: 1;
		background: #48bb78;
		color: white;
		border: none;
		padding: 0.75rem;
		border-radius: 8px;
		font-weight: 500;
		cursor: pointer;
	}

	.cancel-button {
		flex: 1;
		background: #e2e8f0;
		color: #4a5568;
		border: none;
		padding: 0.75rem;
		border-radius: 8px;
		font-weight: 500;
		cursor: pointer;
	}

	/* Stats Section */
	.stats-section {
		margin-bottom: 2rem;
	}

	.section-title {
		font-size: 1.2rem;
		font-weight: 600;
		color: #2d3748;
		margin: 0 0 1rem;
	}

	.stats-grid {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 1rem;
	}

	.stat-card {
		background: white;
		padding: 1rem;
		border-radius: 12px;
		text-align: center;
		border: 2px solid #e2e8f0;
	}

	.stat-number {
		font-size: 1.5rem;
		font-weight: 600;
		color: #667eea;
		margin-bottom: 0.25rem;
	}

	.stat-label {
		font-size: 0.8rem;
		color: #718096;
		margin-bottom: 0.5rem;
	}

	.stat-stars {
		font-size: 0.8rem;
	}

	.star {
		opacity: 0.3;
	}

	.star.filled {
		opacity: 1;
	}

	/* History Section */
	.history-section {
		margin-bottom: 2rem;
	}

	.view-history-btn {
		width: 100%;
		background: white;
		border: 2px solid #e2e8f0;
		border-radius: 12px;
		padding: 1rem;
		display: flex;
		align-items: center;
		cursor: pointer;
		transition: all 0.2s;
	}

	.view-history-btn:hover {
		border-color: #667eea;
		background: #f7fafc;
	}

	.btn-icon {
		font-size: 1.5rem;
		margin-right: 1rem;
	}

	.btn-content {
		flex: 1;
		text-align: left;
	}

	.btn-title {
		display: block;
		font-weight: 600;
		color: #2d3748;
		margin-bottom: 0.25rem;
	}

	.btn-subtitle {
		display: block;
		font-size: 0.9rem;
		color: #718096;
	}

	.btn-arrow {
		color: #cbd5e0;
	}

	/* Contact Section */
	.contact-section {
		margin-bottom: 2rem;
	}

	.contact-info {
		background: white;
		border-radius: 12px;
		padding: 1.5rem;
		border: 2px solid #e2e8f0;
	}

	.contact-item {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 1rem;
	}

	.contact-item:last-child {
		margin-bottom: 0;
	}

	.contact-label {
		font-weight: 500;
		color: #4a5568;
		font-size: 0.9rem;
	}

	.contact-value {
		color: #718096;
		font-size: 0.9rem;
	}

	/* Settings Section */
	.settings-section {
		margin-bottom: 2rem;
	}

	.settings-group {
		background: white;
		border-radius: 12px;
		padding: 1.5rem;
		border: 2px solid #e2e8f0;
		margin-bottom: 1rem;
	}

	.settings-group-title {
		font-size: 1rem;
		font-weight: 600;
		color: #2d3748;
		margin: 0 0 1rem;
	}

	.setting-item {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 1rem;
	}

	.setting-item:last-child {
		margin-bottom: 0;
	}

	.setting-label {
		font-size: 0.9rem;
		color: #4a5568;
	}

	/* Toggle Switch */
	.toggle {
		position: relative;
		display: inline-block;
		width: 50px;
		height: 24px;
	}

	.toggle input {
		opacity: 0;
		width: 0;
		height: 0;
	}

	.toggle-slider {
		position: absolute;
		cursor: pointer;
		top: 0;
		left: 0;
		right: 0;
		bottom: 0;
		background-color: #ccc;
		transition: 0.4s;
		border-radius: 24px;
	}

	.toggle-slider:before {
		position: absolute;
		content: "";
		height: 18px;
		width: 18px;
		left: 3px;
		bottom: 3px;
		background-color: white;
		transition: 0.4s;
		border-radius: 50%;
	}

	.toggle input:checked + .toggle-slider {
		background-color: #667eea;
	}

	.toggle input:checked + .toggle-slider:before {
		transform: translateX(26px);
	}

	/* History Section */
	.history-section {
		margin-bottom: 2rem;
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

	.history-list {
		display: flex;
		flex-direction: column;
		gap: 0.75rem;
	}

	.history-item {
		background: white;
		border-radius: 12px;
		padding: 1rem;
		border: 2px solid #e2e8f0;
		cursor: pointer;
		display: flex;
		justify-content: space-between;
		align-items: center;
		transition: border-color 0.2s, transform 0.2s;
	}

	.history-item:hover {
		border-color: #667eea;
		transform: translateY(-1px);
	}

	.history-header {
		display: flex;
		gap: 0.5rem;
		align-items: center;
		margin-bottom: 0.5rem;
	}

	.currency-badge {
		background: #667eea;
		color: white;
		padding: 0.25rem 0.75rem;
		border-radius: 20px;
		font-size: 0.8rem;
		font-weight: 600;
	}

	.exchange-type {
		padding: 0.25rem 0.75rem;
		border-radius: 20px;
		font-size: 0.8rem;
		font-weight: 500;
	}

	.exchange-type.sold {
		background: #fed7d7;
		color: #c53030;
	}

	.exchange-type.bought {
		background: #c6f6d5;
		color: #22543d;
	}

	.history-amount {
		font-size: 1.2rem;
		font-weight: 600;
		color: #2d3748;
		margin-bottom: 0.5rem;
	}

	.history-details {
		display: flex;
		justify-content: space-between;
		font-size: 0.85rem;
		color: #718096;
		margin-bottom: 0.5rem;
	}

	.history-rating {
		font-size: 0.8rem;
	}

	.history-arrow {
		color: #a0aec0;
	}

	/* Account Actions */
	.account-actions {
		display: flex;
		flex-direction: column;
		gap: 1rem;
	}

	.action-button {
		padding: 1rem;
		border: none;
		border-radius: 12px;
		cursor: pointer;
		font-size: 1rem;
		font-weight: 500;
		display: flex;
		align-items: center;
		justify-content: center;
		gap: 0.5rem;
		transition: transform 0.2s;
	}

	.action-button:hover {
		transform: translateY(-1px);
	}

	.action-button.logout {
		background: #4299e1;
		color: white;
	}

	.action-button.delete {
		background: #fed7d7;
		color: #c53030;
		border: 2px solid #feb2b2;
	}

	/* Responsive adjustments */
	@media (max-width: 375px) {
		.profile-container {
			max-width: 375px;
		}
		
		.content {
			padding: 0 1rem 2rem;
		}
		
		.user-profile {
			margin: -2rem -0.5rem 2rem;
			padding: 2rem 1rem 1.5rem;
		}
		
		.stats-grid {
			grid-template-columns: 1fr;
			gap: 0.75rem;
		}
		
		.stat-card {
			display: flex;
			align-items: center;
			justify-content: space-between;
			text-align: left;
		}
		
		.edit-actions {
			flex-direction: column;
		}
	}

	@media (max-width: 320px) {
		.profile-container {
			max-width: 320px;
		}
		
		.header {
			padding: 1rem;
		}
		
		.content {
			padding: 0 0.75rem 2rem;
		}
		
		.user-details {
			flex-direction: column;
			gap: 0.75rem;
		}
	}
</style>