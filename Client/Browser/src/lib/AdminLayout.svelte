<script>
	import { goto } from '$app/navigation';
	
	function goHome() {
		goto('/');
	}

	function goToSearch() {
		goto('/search');
	}

	function goToTerminal() {
		goto('/terminal');
	}
	
	function goToPaymentReports() {
		goto('/payment-reports');
	}

	function goToPayPalTransactions() {
		goto('/paypal-transactions');
	}

	function goToExchangeRates() {
		goto('/exchange-rates');
	}
</script>

<main class="admin-container">
	<div class="admin-header">
		<div class="header-content">
			<div>
				<button class="home-btn" on:click={goHome}>🏠 Admin Dashboard</button>
				<p>Nice Traders Admin</p>
			</div>
			<div class="header-buttons">			<button class="header-btn" on:click={goToExchangeRates}>💱 Exchange Rates</button>				<button class="header-btn" on:click={goToPaymentReports}>💳 Payment Reports</button>
				<button class="header-btn" on:click={goToPayPalTransactions}>🔄 PayPal</button>
				<button class="header-btn" on:click={goToTerminal}>📋 Terminal</button>
				<button class="header-btn" on:click={goToSearch}>🔍 Search</button>
			</div>
		</div>
	</div>

	<slot />
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

	.header-content {
		display: flex;
		justify-content: space-between;
		align-items: center;
		gap: 20px;
	}

	.header-buttons {
		display: flex;
		gap: 10px;
		flex-wrap: wrap;
	}

	.home-btn {
		background: none;
		border: none;
		color: white;
		font-size: 1.5rem;
		font-weight: 600;
		cursor: pointer;
		padding: 0;
		margin: 0 0 10px 0;
		font-family: inherit;
		transition: opacity 0.2s;
	}

	.home-btn:hover {
		opacity: 0.9;
	}

	.admin-header p {
		margin: 0;
		opacity: 0.9;
	}

	.header-btn {
		padding: 10px 20px;
		border: 2px solid white;
		background: rgba(255, 255, 255, 0.2);
		color: white;
		border-radius: 8px;
		cursor: pointer;
		font-weight: 600;
		font-size: 0.95rem;
		transition: all 0.2s;
		white-space: nowrap;
	}

	.header-btn:hover {
		background: white;
		color: #667eea;
		transform: translateY(-2px);
	}
</style>
