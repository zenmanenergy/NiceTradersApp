<script>
	import { goto } from '$app/navigation';
	
	console.log('[Home Page] Loaded');
</script>

<div class="admin-home">
	<div class="welcome-section">
		<h1>Admin Dashboard</h1>
		<p>Welcome to the Nice Traders Admin Panel</p>
	</div>

	<div class="quick-actions">
		<h2>Quick Actions</h2>
		<div class="action-grid">
			<button class="action-card" on:click={() => {
				console.log('[Home] Navigating to search');
				goto('/search');
			}}>
				<div class="card-icon">🔍</div>
				<div class="card-title">Search</div>
				<div class="card-description">Search users, listings, and transactions</div>
			</button>
			
			<button class="action-card" on:click={() => goto('/exchange-rates')}>
				<div class="card-icon">💱</div>
				<div class="card-title">Exchange Rates</div>
				<div class="card-description">View and manage currency rates</div>
			</button>
			
			<button class="action-card" on:click={() => goto('/logs')}>
				<div class="card-icon">📋</div>
				<div class="card-title">View Logs</div>
				<div class="card-description">Monitor application logs</div>
			</button>
			
			<button class="action-card" on:click={() => goto('/payment-reports')}>
				<div class="card-icon">💳</div>
				<div class="card-title">Payment Reports</div>
				<div class="card-description">View payment and transaction data</div>
			</button>
			
			<button class="action-card" on:click={() => goto('/paypal-transactions')}>
				<div class="card-icon">🔄</div>
				<div class="card-title">PayPal Transactions</div>
				<div class="card-description">View and refund PayPal payments</div>
			</button>

			<button class="action-card" on:click={() => goto('/localization')}>
				<div class="card-icon">🌐</div>
				<div class="card-title">Localization Editor</div>
				<div class="card-description">Manage all translations and i18n content</div>
			</button>
		</div>
	</div>

	<div class="admin-info">
		<h2>Admin Info</h2>
		<p>Use the navigation buttons above to access different admin sections.</p>
	</div>
</div>

<style>
	.admin-home {
		padding: 40px 20px;
		max-width: 1200px;
		margin: 0 auto;
	}

	.welcome-section {
		text-align: center;
		margin-bottom: 50px;
	}

	.welcome-section h1 {
		font-size: 2.5rem;
		margin: 0 0 10px 0;
		color: #333;
	}

	.welcome-section p {
		font-size: 1.1rem;
		color: #666;
		margin: 0;
	}

	.quick-actions {
		margin-bottom: 50px;
	}

	.quick-actions h2 {
		font-size: 1.5rem;
		margin: 0 0 30px 0;
		color: #333;
	}

	.action-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
		gap: 20px;
	}

	.action-card {
		background: white;
		border: 2px solid #e0e0e0;
		border-radius: 12px;
		padding: 30px 20px;
		cursor: pointer;
		transition: all 0.3s ease;
		display: flex;
		flex-direction: column;
		align-items: center;
		text-align: center;
		font-family: inherit;
		font-size: 1rem;
	}

	.action-card:hover {
		border-color: #667eea;
		box-shadow: 0 8px 20px rgba(102, 126, 234, 0.15);
		transform: translateY(-5px);
	}

	.card-icon {
		font-size: 3rem;
		margin-bottom: 15px;
	}

	.card-title {
		font-size: 1.2rem;
		font-weight: 600;
		color: #333;
		margin-bottom: 8px;
	}

	.card-description {
		font-size: 0.9rem;
		color: #666;
		margin: 0;
	}

	.admin-info {
		background: #f5f7fa;
		padding: 30px;
		border-radius: 12px;
	}

	.admin-info h2 {
		margin: 0 0 15px 0;
		color: #333;
	}

	.admin-info p {
		margin: 0;
		color: #666;
	}
</style>
