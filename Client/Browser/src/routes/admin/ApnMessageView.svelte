<script>
	import { viewState, userDetailState } from '../../lib/adminStore';
	import SuperFetch from '../../SuperFetch.js';

	let messageTitle = '';
	let messageBody = '';
	let badge = 1;
	let sound = 'default';
	let isSending = false;
	let sendResult = null;
	let showResult = false;

	// Get active iOS devices
	$: activeIOSDevices = $userDetailState.userDevices.filter(d => 
		d.device_type === 'ios' && d.device_token && d.is_active === 1
	);

	$: hasActiveDevices = activeIOSDevices.length > 0;

	async function sendMessage() {
		if (!messageTitle.trim()) {
			alert('Please enter a notification title');
			return;
		}

		if (!messageBody.trim()) {
			alert('Please enter a notification message');
			return;
		}

		if (!hasActiveDevices) {
			alert('No active iOS devices found for this user. Devices must be marked as active and have a valid device token.');
			return;
		}

		isSending = true;
		showResult = false;

		try {
			const response = await SuperFetch('/Admin/SendApnMessage', {
				user_id: $userDetailState.currentUser.UserId,
				title: messageTitle,
				body: messageBody,
				badge: badge,
				sound: sound
			});

			if (response && response.success) {
				sendResult = {
					success: true,
					message: response.message || 'Message sent successfully'
				};
				messageTitle = '';
				messageBody = '';
				badge = 1;
			} else {
				sendResult = {
					success: false,
					message: response?.error || 'Failed to send message'
				};
			}
		} catch (error) {
			sendResult = {
				success: false,
				message: error.message || 'Error sending message'
			};
		} finally {
			isSending = false;
			showResult = true;
			setTimeout(() => {
				showResult = false;
			}, 5000);
		}
	}

	function goBack() {
		viewState.update(state => ({
			...state,
			currentView: 'user'
		}));
	}
</script>

<div class="message-view">
	<div class="header">
		<button class="back-btn" on:click={goBack}>← Back</button>
		<h2>Send APN Message</h2>
		<div class="user-info">
			<strong>{$userDetailState.currentUser.FirstName} {$userDetailState.currentUser.LastName}</strong>
			<span class="email">{$userDetailState.currentUser.Email}</span>
		</div>
	</div>

	<div class="form-container">
		<!-- Device Status Section -->
		<div class="device-status-section">
			<h3>📱 Registered iOS Devices</h3>
			{#if $userDetailState.userDevices.length === 0}
				<div class="alert alert-warning">
					⚠️ No devices registered for this user
				</div>
			{:else}
				<div class="devices-info">
					{#each $userDetailState.userDevices as device}
						<div class="device-item {device.device_type === 'ios' ? 'ios' : 'other'}">
							<div class="device-header-row">
								<div class="device-type-badge">
									{#if device.device_type === 'ios'}
										📱 iOS
									{:else if device.device_type === 'android'}
										🤖 Android
									{:else}
										🌐 {device.device_type}
									{/if}
								</div>
								<div class="device-status">
									{#if device.device_type === 'ios' && device.is_active === 1 && device.device_token}
										<span class="badge badge-success">✓ Ready</span>
									{:else}
										<span class="badge badge-warning">⚠ Not Ready</span>
									{/if}
								</div>
							</div>
							<div class="device-details">
								{#if device.device_name}
									<div><strong>Name:</strong> {device.device_name}</div>
								{/if}
								<div><strong>Type:</strong> {device.device_type}</div>
								{#if device.app_version}
									<div><strong>App:</strong> {device.app_version}</div>
								{/if}
								<div>
									<strong>Token:</strong>
									<span class="device-token-indicator {device.device_token ? 'has-token' : 'no-token'}">
										{device.device_token ? '✓ Registered' : '✗ Missing'}
									</span>
								</div>
								<div>
									<strong>Active:</strong>
									<span class="active-indicator {device.is_active ? 'active' : 'inactive'}">
										{device.is_active ? 'Yes' : 'No'}
									</span>
								</div>
							</div>
						</div>
					{/each}
				</div>

				{#if !hasActiveDevices}
					<div class="alert alert-error">
						❌ No active iOS devices with valid tokens. Cannot send notification.
						<br/>
						The user needs to:
						<ul>
							<li>Install the app on an iOS device</li>
							<li>Log in and allow push notifications</li>
							<li>Device must be marked as active in the database</li>
						</ul>
					</div>
				{:else}
					<div class="alert alert-success">
						✓ {activeIOSDevices.length} active device(s) ready to receive notifications
					</div>
				{/if}
			{/if}
		</div>

		<!-- Message Form -->
		<div class="form-group">
			<label for="title">Notification Title</label>
			<input
				id="title"
				type="text"
				bind:value={messageTitle}
				placeholder="Enter notification title"
				disabled={isSending || !hasActiveDevices}
				maxlength="100"
			/>
			<span class="char-count">{messageTitle.length}/100</span>
		</div>

		<div class="form-group">
			<label for="body">Message Body</label>
			<textarea
				id="body"
				bind:value={messageBody}
				placeholder="Enter notification message"
				rows="5"
				disabled={isSending || !hasActiveDevices}
				maxlength="500"
			></textarea>
			<span class="char-count">{messageBody.length}/500</span>
		</div>

		<div class="form-row">
			<div class="form-group">
				<label for="badge">Badge Number</label>
				<input
					id="badge"
					type="number"
					bind:value={badge}
					min="0"
					max="999"
					disabled={isSending || !hasActiveDevices}
				/>
			</div>

			<div class="form-group">
				<label for="sound">Sound</label>
				<select id="sound" bind:value={sound} disabled={isSending || !hasActiveDevices}>
					<option value="default">Default</option>
					<option value="silent">Silent</option>
				</select>
			</div>
		</div>

		<div class="button-group">
			<button on:click={goBack} disabled={isSending} class="btn-cancel">Cancel</button>
			<button 
				on:click={sendMessage} 
				disabled={isSending || !hasActiveDevices} 
				class="btn-send"
				title={!hasActiveDevices ? 'No active devices available' : 'Send notification'}
			>
				{isSending ? 'Sending...' : `Send to ${activeIOSDevices.length} Device(s)`}
			</button>
		</div>

		{#if showResult}
			<div class="result {sendResult.success ? 'success' : 'error'}">
				{#if sendResult.success}
					<div class="result-icon">✓</div>
				{:else}
					<div class="result-icon">✕</div>
				{/if}
				<p>{sendResult.message}</p>
			</div>
		{/if}
	</div>
</div>

<style>
	.message-view {
		background: white;
		border-radius: 8px;
		box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
		overflow: hidden;
	}

	.header {
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		color: white;
		padding: 24px;
		display: flex;
		align-items: center;
		gap: 16px;
	}

	.back-btn {
		background: rgba(255, 255, 255, 0.2);
		border: none;
		color: white;
		padding: 8px 12px;
		border-radius: 4px;
		cursor: pointer;
		font-size: 14px;
		transition: background 0.2s;
	}

	.back-btn:hover {
		background: rgba(255, 255, 255, 0.3);
	}

	.header h2 {
		margin: 0;
		font-size: 24px;
		flex: 1;
	}

	.user-info {
		display: flex;
		flex-direction: column;
		font-size: 14px;
		text-align: right;
	}

	.email {
		opacity: 0.9;
		font-size: 13px;
		margin-top: 4px;
	}

	.form-container {
		padding: 32px;
		max-width: 600px;
	}

	.device-status-section {
		margin-bottom: 32px;
		padding-bottom: 32px;
		border-bottom: 2px solid #e0e0e0;
	}

	.device-status-section h3 {
		margin: 0 0 16px 0;
		color: #333;
		font-size: 1.1rem;
	}

	.devices-info {
		display: grid;
		gap: 12px;
		margin-bottom: 16px;
	}

	.device-item {
		padding: 14px;
		background: #f8f9fa;
		border: 2px solid #e2e8f0;
		border-radius: 6px;
		transition: all 0.2s;
	}

	.device-item.ios {
		border-color: #667eea;
		background: #f0f3ff;
	}

	.device-item.other {
		opacity: 0.6;
	}

	.device-header-row {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 10px;
	}

	.device-type-badge {
		font-weight: 600;
		color: #333;
	}

	.device-status {
		display: flex;
		gap: 8px;
	}

	.badge {
		padding: 4px 10px;
		border-radius: 4px;
		font-size: 0.8rem;
		font-weight: 600;
	}

	.badge-success {
		background: #dcfce7;
		color: #166534;
	}

	.badge-warning {
		background: #fef3c7;
		color: #92400e;
	}

	.device-details {
		font-size: 0.85rem;
		color: #666;
		display: grid;
		gap: 6px;
	}

	.device-details div {
		display: flex;
		gap: 8px;
	}

	.device-details strong {
		color: #333;
		min-width: 70px;
	}

	.device-token-indicator,
	.active-indicator {
		padding: 2px 6px;
		border-radius: 3px;
		font-size: 0.8rem;
		font-weight: 500;
	}

	.device-token-indicator.has-token {
		background: #dcfce7;
		color: #166534;
	}

	.device-token-indicator.no-token {
		background: #fee2e2;
		color: #991b1b;
	}

	.active-indicator.active {
		background: #dcfce7;
		color: #166534;
	}

	.active-indicator.inactive {
		background: #fecaca;
		color: #991b1b;
	}

	.alert {
		padding: 12px 16px;
		border-radius: 6px;
		font-size: 0.9rem;
		line-height: 1.5;
		margin-bottom: 16px;
	}

	.alert ul {
		margin: 8px 0 0 20px;
		padding: 0;
	}

	.alert li {
		margin: 4px 0;
	}

	.alert-warning {
		background: #fef3c7;
		border-left: 4px solid #f59e0b;
		color: #92400e;
	}

	.alert-error {
		background: #fee2e2;
		border-left: 4px solid #ef4444;
		color: #991b1b;
	}

	.alert-success {
		background: #dcfce7;
		border-left: 4px solid #22c55e;
		color: #166534;
	}

	.form-group {
		margin-bottom: 24px;
		position: relative;
	}

	.form-group label {
		display: block;
		margin-bottom: 8px;
		font-weight: 600;
		color: #333;
		font-size: 14px;
	}

	.form-group input,
	.form-group textarea,
	.form-group select {
		width: 100%;
		padding: 12px;
		border: 2px solid #e0e0e0;
		border-radius: 6px;
		font-size: 14px;
		font-family: inherit;
		transition: border-color 0.2s;
	}

	.form-group input:focus,
	.form-group textarea:focus,
	.form-group select:focus {
		outline: none;
		border-color: #667eea;
		box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
	}

	.form-group input:disabled,
	.form-group textarea:disabled,
	.form-group select:disabled {
		background-color: #f5f5f5;
		color: #999;
		cursor: not-allowed;
	}

	.form-group textarea {
		resize: vertical;
		min-height: 120px;
	}

	.char-count {
		position: absolute;
		top: 32px;
		right: 0;
		font-size: 12px;
		color: #999;
	}

	.form-row {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 16px;
	}

	.button-group {
		display: flex;
		gap: 12px;
		margin-top: 32px;
	}

	button {
		padding: 12px 24px;
		border: none;
		border-radius: 6px;
		font-size: 14px;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.2s;
	}

	.btn-cancel {
		flex: 1;
		background-color: #f0f0f0;
		color: #333;
	}

	.btn-cancel:hover:not(:disabled) {
		background-color: #e0e0e0;
	}

	.btn-send {
		flex: 1;
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		color: white;
	}

	.btn-send:hover:not(:disabled) {
		transform: translateY(-2px);
		box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
	}

	.btn-send:disabled {
		opacity: 0.6;
		cursor: not-allowed;
	}

	.result {
		margin-top: 24px;
		padding: 16px;
		border-radius: 6px;
		display: flex;
		align-items: flex-start;
		gap: 12px;
		animation: slideIn 0.3s ease;
	}

	.result.success {
		background-color: #f0fdf4;
		border-left: 4px solid #22c55e;
		color: #166534;
	}

	.result.error {
		background-color: #fef2f2;
		border-left: 4px solid #ef4444;
		color: #991b1b;
	}

	.result-icon {
		font-size: 20px;
		font-weight: bold;
		min-width: 24px;
	}

	.result p {
		margin: 0;
		font-size: 14px;
	}

	@keyframes slideIn {
		from {
			opacity: 0;
			transform: translateY(-8px);
		}
		to {
			opacity: 1;
			transform: translateY(0);
		}
	}

	@media (max-width: 600px) {
		.header {
			flex-direction: column;
			text-align: center;
		}

		.user-info {
			text-align: center;
		}

		.form-container {
			padding: 16px;
		}

		.form-row {
			grid-template-columns: 1fr;
		}
	}
</style>
