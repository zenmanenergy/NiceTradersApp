<script>
	import SuperFetch from '../../../SuperFetch.js';
	import { formatDate, formatCurrency } from '../../../lib/adminUtils.js';
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';
	import AdminLayout from '$lib/AdminLayout.svelte';
	import { onMount } from 'svelte';
	
	let editMode = false;
	let editFormData = {};
	let editLoading = false;
	let editError = null;
	let editSuccess = false;
	
	let user = null;
	let userListings = [];
	let userPurchases = [];
	let userMessages = [];
	let userDevices = [];
	let loading = true;
	let error = null;
	
	$: if (user && !editFormData.Email) {
		editFormData = { ...user };
	}
	
	onMount(async () => {
		await loadUserData();
	});
	
	async function loadUserData() {
		loading = true;
		error = null;
		
		try {
			const userId = $page.params.id;
			const API_URL = 'https://api.nicetraders.net';
			
			// Fetch user data
			const userRes = await fetch(`${API_URL}/Admin/GetUserById`, {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ user_id: userId })
			});
			const userData = await userRes.json();
			
			if (!userData.success) {
				throw new Error('User not found');
			}
			user = userData.user;
			
			// Fetch user listings
			const listingsRes = await fetch(`${API_URL}/Admin/GetUserListings`, {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ user_id: userId })
			});
			const listingsData = await listingsRes.json();
			userListings = listingsData.listings || [];
			
			// Fetch user purchases
			const purchasesRes = await fetch(`${API_URL}/Admin/GetUserPurchases`, {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ user_id: userId })
			});
			const purchasesData = await purchasesRes.json();
			userPurchases = purchasesData.purchases || [];
			
			// Fetch user messages
			const messagesRes = await fetch(`${API_URL}/Admin/GetUserMessages`, {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ user_id: userId })
			});
			const messagesData = await messagesRes.json();
			userMessages = messagesData.messages || [];
			
			// Fetch user devices
			const devicesRes = await fetch(`${API_URL}/Admin/GetUserDevices`, {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ user_id: userId })
			});
			const devicesData = await devicesRes.json();
			userDevices = devicesData.devices || [];
			
		} catch (err) {
			console.error('Error loading user:', err);
			error = err.message || 'Failed to load user';
		} finally {
			loading = false;
		}
	}
	
	async function toggleEditMode() {
		editMode = !editMode;
		editError = null;
		editSuccess = false;
	}
	
	async function saveUserChanges() {
		editLoading = true;
		editError = null;
		editSuccess = false;
		
		try {
			const response = await SuperFetch('/Admin/UpdateUser', {
				user_id: user.user_id,
				...editFormData
			});
			
			if (response.success) {
				user = { ...user, ...editFormData };
				editSuccess = true;
				setTimeout(() => {
					editSuccess = false;
					editMode = false;
				}, 2000);
			} else {
				editError = response.error || 'Failed to update user';
			}
		} catch (err) {
			editError = err.message;
		} finally {
			editLoading = false;
		}
	}

	function sendApnMessage() {
		goto(`/apn-message/${user.user_id}`);
	}
	
	function viewListing(listingId) {
		goto(`/listing/${listingId}`);
	}
	
	function viewTransaction(transactionId) {
		goto(`/transaction/${transactionId}`);
	}
</script>


<AdminLayout>
	{#if user}
		<div class="detail-view">
		<div class="detail-header">
			<h2>👤 {user.FirstName} {user.LastName}</h2>
			<span class="badge {user.IsActive ? 'active' : 'inactive'}">
				{user.IsActive ? 'Active' : 'Inactive'}
			</span>
		</div>
		
		{#if editMode}
			<div class="edit-user-form">
				<div class="form-row">
					<div class="form-field">
						<label>First Name</label>
						<input type="text" bind:value={editFormData.FirstName} />
					</div>
					<div class="form-field">
						<label>Last Name</label>
						<input type="text" bind:value={editFormData.LastName} />
					</div>
				</div>
				
				<div class="form-row">
					<div class="form-field">
						<label>Email</label>
						<input type="email" bind:value={editFormData.Email} />
					</div>
					<div class="form-field">
						<label>Phone</label>
						<input type="tel" bind:value={editFormData.Phone} />
					</div>
				</div>
				
				<div class="form-row">
					<div class="form-field">
						<label>Location</label>
						<input type="text" bind:value={editFormData.Location} />
					</div>
				</div>
				
				<div class="form-row">
					<div class="form-field">
						<label>Bio</label>
						<textarea bind:value={editFormData.Bio} rows="3"></textarea>
					</div>
				</div>
				
				<div class="form-row toggle-row">
					<label>
						<input type="checkbox" bind:checked={editFormData.IsActive} />
						Active
					</label>
				</div>
				
				<div class="form-actions">
					<button class="save-btn" on:click={saveUserChanges} disabled={editLoading}>
						{editLoading ? 'Saving...' : 'Save'}
					</button>
					<button class="cancel-btn" on:click={toggleEditMode}>Cancel</button>
				</div>
				
				{#if editError}
					<div class="form-feedback error">{editError}</div>
				{/if}
				{#if editSuccess}
					<div class="form-feedback success">User updated successfully!</div>
				{/if}
			</div>
		{:else}
			<div class="detail-grid">
				<div class="info-card">
					<h3>Contact Information</h3>
					<div class="info-row"><strong>Email:</strong> {user.Email}</div>
					<div class="info-row"><strong>Phone:</strong> {user.Phone || '-'}</div>
					<div class="info-row"><strong>Location:</strong> {user.Location || '-'}</div>
					<div class="info-row"><strong>Bio:</strong> {user.Bio || '-'}</div>
				</div>
				
				<div class="info-card">
					<h3>Statistics</h3>
					<div class="info-row"><strong>Rating:</strong> {user.Rating} ⭐</div>
					<div class="info-row"><strong>Total Exchanges:</strong> {user.TotalExchanges}</div>
					<div class="info-row"><strong>User Type:</strong> {user.UserType}</div>
					<div class="info-row"><strong>Joined:</strong> {formatDate(user.DateCreated)}</div>
				</div>
			</div>
			
			<div class="action-buttons">
				<button class="edit-user-btn" on:click={toggleEditMode}>✏️ Edit User</button>
				<button class="send-apn-btn" on:click={sendApnMessage}>🔔 Send APN Message</button>
			</div>
		{/if}

		<div class="section">
			<h3>📋 Listings ({userListings.length})</h3>
			{#if userListings.length === 0}
				<p class="empty-state">No listings</p>
			{:else}
				<div class="list-grid">
					{#each userListings as listing}
						<div class="list-card" on:click={() => viewListing(listing.listing_id)}>
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
						<div class="list-card" on:click={() => viewTransaction(purchase.access_id)}>
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

		<div class="section">
			<h3>📱 Registered Devices ({userDevices.length})</h3>
			{#if userDevices.length === 0}
				<p class="empty-state">No registered devices</p>
			{:else}
				<div class="devices-list">
					{#each userDevices as device}
						<div class="device-card">
							<div class="device-header">
								<div class="device-type">
									{#if device.device_type === 'ios'}
										📱 iOS
									{:else if device.device_type === 'android'}
										🤖 Android
									{:else}
										🌐 Web
									{/if}
									{device.device_name ? ` - ${device.device_name}` : ''}
								</div>
								<span class="status-badge {device.is_active ? 'active' : 'inactive'}">
									{device.is_active ? 'Active' : 'Inactive'}
								</span>
							</div>
							<div class="device-info">
								<div class="info-row">
									<strong>Device Token:</strong>
									<span class="device-token" title={device.device_token || 'No token'}>
										{device.device_token ? device.device_token.substring(0, 40) + '...' : 'Not yet registered'}
									</span>
								</div>
								<div class="info-row">
									<strong>Device ID:</strong>
									<span class="device-id">{device.device_id}</span>
								</div>
								{#if device.app_version}
									<div class="info-row">
										<strong>App Version:</strong> {device.app_version}
									</div>
								{/if}
								{#if device.os_version}
									<div class="info-row">
										<strong>OS Version:</strong> {device.os_version}
									</div>
								{/if}
								<div class="info-row">
									<strong>Registered:</strong> {formatDate(device.registered_at)}
								</div>
								{#if device.last_used_at}
									<div class="info-row">
										<strong>Last Used:</strong> {formatDate(device.last_used_at)}
									</div>
								{/if}
							</div>
						</div>
					{/each}
				</div>
			{/if}
		</div>
	</div>
	{/if}
</AdminLayout>

<style>
	.detail-view {
		background: white;
		padding: 30px;
		border-radius: 12px;
		box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
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

	.info-card h3 {
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

	.edit-user-btn {
		background: #38b2ac;
		border: none;
		color: white;
		padding: 10px 20px;
		border-radius: 6px;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.2s;
		margin-bottom: 20px;
	}

	.edit-user-btn:hover {
		background: #319795;
	}

	.action-buttons {
		display: flex;
		gap: 12px;
		margin-bottom: 20px;
		flex-wrap: wrap;
	}

	.send-apn-btn {
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		border: none;
		color: white;
		padding: 10px 20px;
		border-radius: 6px;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.2s;
	}

	.send-apn-btn:hover {
		transform: translateY(-2px);
		box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
	}

	.edit-user-form {
		background: #f8f9fa;
		padding: 20px;
		border-radius: 10px;
		border: 1px solid #e2e8f0;
		margin-bottom: 20px;
	}

	.form-row {
		display: flex;
		gap: 16px;
		flex-wrap: wrap;
		margin-bottom: 12px;
	}

	.form-row.toggle-row {
		align-items: center;
	}

	.form-field {
		flex: 1;
		display: flex;
		flex-direction: column;
		gap: 6px;
	}

	.form-field label {
		font-weight: 600;
		color: #333;
		font-size: 0.9rem;
	}

	.form-field input,
	.form-field textarea {
		padding: 10px;
		border-radius: 6px;
		border: 1px solid #cbd5f5;
		font-size: 0.95rem;
		font-family: inherit;
	}

	.form-field textarea {
		resize: vertical;
	}

	.toggle-field {
		flex-direction: row;
		align-items: center;
		gap: 8px;
	}

	.form-actions {
		display: flex;
		gap: 12px;
		flex-wrap: wrap;
		margin-top: 16px;
	}

	.save-btn,
	.cancel-btn {
		padding: 10px 18px;
		border-radius: 6px;
		border: none;
		font-weight: 600;
		font-size: 0.95rem;
		cursor: pointer;
	}

	.save-btn {
		background: #2b6cb0;
		color: white;
	}

	.save-btn:disabled {
		background: #999;
		cursor: not-allowed;
	}

	.cancel-btn {
		background: #e2e8f0;
		color: #2d3748;
	}

	.form-feedback {
		margin: 12px 0 0;
		font-size: 0.9rem;
	}

	.form-feedback.success {
		color: #2f855a;
	}

	.form-feedback.error {
		color: #c53030;
	}

	.devices-list {
		display: grid;
		gap: 16px;
	}

	.device-card {
		background: #f8f9fa;
		padding: 18px;
		border-radius: 10px;
		border: 2px solid #e2e8f0;
		transition: all 0.2s;
	}

	.device-card:hover {
		border-color: #667eea;
		box-shadow: 0 2px 8px rgba(102, 126, 234, 0.1);
	}

	.device-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 12px;
		padding-bottom: 12px;
		border-bottom: 1px solid #e2e8f0;
	}

	.device-type {
		font-weight: 600;
		font-size: 1.05rem;
		color: #333;
	}

	.device-info {
		display: grid;
		gap: 8px;
	}

	.device-info .info-row {
		display: flex;
		gap: 8px;
		align-items: flex-start;
		font-size: 0.9rem;
	}

	.device-info .info-row strong {
		color: #666;
		min-width: 120px;
		flex-shrink: 0;
	}

	.device-token {
		font-family: 'Monaco', 'Courier New', monospace;
		font-size: 0.85rem;
		color: #667eea;
		word-break: break-all;
		background: white;
		padding: 4px 8px;
		border-radius: 4px;
		border: 1px solid #e2e8f0;
		cursor: help;
	}

	.device-id {
		font-family: 'Monaco', 'Courier New', monospace;
		font-size: 0.85rem;
		color: #555;
	}

	@media (max-width: 768px) {
		.detail-grid {
			grid-template-columns: 1fr;
		}

		.list-grid {
			grid-template-columns: 1fr;
		}
	}
</style>
