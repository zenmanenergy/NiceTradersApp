<script>
	import { viewState } from '../../lib/adminStore.js';
	
	function resetToSearch() {
		$viewState = {
			currentView: 'search',
			breadcrumbs: []
		};
	}
	
	function goToLogs() {
		$viewState = {
			currentView: 'logs',
			breadcrumbs: []
		};
	}
	
	function goToPaymentReports() {
		$viewState = {
			currentView: 'payment-reports',
			breadcrumbs: []
		};
	}
	
	function goBack() {
		if ($viewState.breadcrumbs.length > 0) {
			$viewState.breadcrumbs.pop();
			if ($viewState.breadcrumbs.length === 0) {
				$viewState.currentView = 'search';
			} else {
				const last = $viewState.breadcrumbs[$viewState.breadcrumbs.length - 1];
				// Navigate will be handled by parent
			}
			$viewState = $viewState;
		} else {
			$viewState.currentView = 'search';
			$viewState = $viewState;
		}
	}
</script>

<main class="admin-container">
	<div class="admin-header">
		<div class="header-content">
			<div>
				<h1>🔧 Admin Dashboard</h1>
				<p>Nice Traders Admin</p>
			</div>
			<div class="header-buttons">
				<button class="logs-btn" on:click={goToPaymentReports}>💳 Payment Reports</button>
				<button class="logs-btn" on:click={goToLogs}>📋 View Logs</button>
			</div>
		</div>
	</div>
	
	{#if $viewState.breadcrumbs && $viewState.breadcrumbs.length > 0}
		<div class="breadcrumb-nav">
			<button class="breadcrumb-btn" on:click={resetToSearch}>🏠 Home</button>
			{#each $viewState.breadcrumbs as crumb}
				<span class="breadcrumb-separator">›</span>
				<span class="breadcrumb-item">{crumb.label}</span>
			{/each}
			<button class="back-btn" on:click={goBack}>← Back</button>
		</div>
	{/if}

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

	.admin-header h1 {
		margin: 0 0 10px 0;
		font-size: 2rem;
	}

	.admin-header p {
		margin: 0;
		opacity: 0.9;
	}

	.logs-btn {
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

	.logs-btn:hover {
		background: white;
		color: #667eea;
		transform: translateY(-2px);
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
</style>
