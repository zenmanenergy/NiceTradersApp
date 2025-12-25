<script>
	import { onMount } from 'svelte';
	import { Settings } from '../../Settings.js';
	
	let exchangeRates = [];
	let lastUpdateDate = null;
	let lastUpdateTime = null;
	let loading = false;
	let refreshing = false;
	let error = null;
	let totalRates = 0;
	let searchTerm = '';
	const API_BASE = Settings.baseURL;
	
	async function loadExchangeRates() {
		loading = true;
		error = null;
		try {
			const url = `${API_BASE}/Admin/GetExchangeRates`;
			console.log(`📈 Loading exchange rates from: ${url}`);
			const response = await fetch(url);
			
			console.log('Status:', response.status, 'Content-Type:', response.headers.get('content-type'));
			
			const text = await response.text();
			let data;
			try {
				data = JSON.parse(text);
			} catch (parseErr) {
				console.error('JSON Parse Error:', parseErr.message);
				console.error('Response:', text.substring(0, 200));
				error = `Failed to load exchange rates: Invalid JSON response`;
				loading = false;
				return;
			}
			
			if (data.success) {
				exchangeRates = data.rates || [];
				lastUpdateDate = data.last_update_date;
				lastUpdateTime = data.last_update_time;
				totalRates = data.total_rates || 0;
				console.log('✅ Exchange rates loaded successfully');
			} else {
				error = data.error || 'Failed to load exchange rates';
				console.error('❌ Server error:', data.error);
			}
		} catch (e) {
			error = 'Network error: ' + e.message;
			console.error('❌ Fetch error:', e);
		} finally {
			loading = false;
		}
	}
	
	async function refreshRates() {
		refreshing = true;
		error = null;
		try {
			const url = `${API_BASE}/Admin/RefreshExchangeRates`;
			console.log(`🔄 Refreshing exchange rates at: ${url}`);
			const response = await fetch(url, {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' }
			});
			
			const text = await response.text();
			let data;
			try {
				data = JSON.parse(text);
			} catch (parseErr) {
				console.error('JSON Parse Error:', parseErr.message);
				error = 'Invalid response from server';
				refreshing = false;
				return;
			}
			
			if (data.success) {
				console.log('✅ Exchange rates refreshed successfully');
				// Reload the rates after successful refresh
				await loadExchangeRates();
			} else {
				error = data.error || 'Failed to refresh exchange rates';
				console.error('❌ Server error:', data.error);
			}
		} catch (e) {
			error = 'Network error: ' + e.message;
		} finally {
			refreshing = false;
		}
	}
	
	onMount(() => {
		loadExchangeRates();
	});
	
	$: filteredRates = exchangeRates.filter(rate => 
		rate.currency_code.toLowerCase().includes(searchTerm.toLowerCase())
	);
	
	function formatDate(dateStr) {
		if (!dateStr) return 'Never';
		const date = new Date(dateStr);
		return date.toLocaleDateString('en-US', { 
			year: 'numeric', 
			month: 'short', 
			day: 'numeric',
			hour: '2-digit',
			minute: '2-digit'
		});
	}
	
	function formatRate(rate) {
		return parseFloat(rate).toFixed(6);
	}
</script>

<div class="exchange-rates-container">
	<div class="header">
		<h1>💱 Exchange Rates Management</h1>
		<p>Monitor and manage currency exchange rates</p>
	</div>

	{#if error}
		<div class="error-banner">
			<span>⚠️ {error}</span>
			<button on:click={() => error = null}>×</button>
		</div>
	{/if}

	<div class="status-panel">
		<div class="status-item">
			<span class="label">Total Rates:</span>
			<span class="value">{totalRates} currencies</span>
		</div>
		<div class="status-item">
			<span class="label">Last Updated:</span>
			<span class="value">{formatDate(lastUpdateTime) || 'No data'}</span>
		</div>
		<div class="status-item">
			<span class="label">Update Date:</span>
			<span class="value">{lastUpdateDate ? new Date(lastUpdateDate).toLocaleDateString() : 'No data'}</span>
		</div>
		<button 
			class="refresh-btn" 
			on:click={refreshRates}
			disabled={refreshing || loading}
		>
			{refreshing ? '⏳ Refreshing...' : '🔄 Refresh Rates Now'}
		</button>
	</div>

	<div class="search-section">
		<input 
			type="text" 
			placeholder="Search currency code (e.g., USD, EUR, JPY)..."
			bind:value={searchTerm}
			class="search-input"
		/>
		<span class="search-info">{filteredRates.length} of {totalRates} currencies</span>
	</div>

	{#if loading}
		<div class="loading">
			<div class="spinner"></div>
			<p>Loading exchange rates...</p>
		</div>
	{:else if filteredRates.length > 0}
		<div class="rates-table">
			<table>
				<thead>
					<tr>
						<th>Currency Code</th>
						<th>Rate to USD</th>
						<th>Last Updated</th>
						<th>Date Retrieved</th>
					</tr>
				</thead>
				<tbody>
					{#each filteredRates as rate (rate.currency_code)}
						<tr class="rate-row">
							<td class="currency-code">{rate.currency_code}</td>
							<td class="rate-value">{formatRate(rate.rate_to_usd)}</td>
							<td class="timestamp">{formatDate(rate.last_updated)}</td>
							<td class="date-retrieved">
								{rate.date_retrieved ? new Date(rate.date_retrieved).toLocaleDateString() : '-'}
							</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	{:else if !loading}
		<div class="empty-state">
			<p>No exchange rates found</p>
			{#if searchTerm}
				<p class="hint">Try adjusting your search</p>
			{:else}
				<p class="hint">Click "Refresh Rates Now" to download exchange rates</p>
			{/if}
		</div>
	{/if}
</div>

<style>
	.exchange-rates-container {
		max-width: 1200px;
		margin: 0 auto;
		padding: 20px;
	}

	.header {
		margin-bottom: 30px;
	}

	.header h1 {
		font-size: 2rem;
		margin: 0 0 10px 0;
		color: #333;
	}

	.header p {
		margin: 0;
		color: #666;
		font-size: 1.1rem;
	}

	.error-banner {
		background-color: #fee;
		border-left: 4px solid #f44;
		padding: 15px;
		margin-bottom: 20px;
		border-radius: 4px;
		display: flex;
		justify-content: space-between;
		align-items: center;
		color: #c00;
	}

	.error-banner button {
		background: none;
		border: none;
		font-size: 1.5rem;
		cursor: pointer;
		color: #c00;
		padding: 0;
		width: 30px;
		height: 30px;
	}

	.status-panel {
		background: white;
		border-radius: 8px;
		padding: 20px;
		box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
		display: flex;
		gap: 20px;
		margin-bottom: 20px;
		flex-wrap: wrap;
		align-items: center;
	}

	.status-item {
		display: flex;
		gap: 10px;
		align-items: center;
	}

	.status-item .label {
		font-weight: 600;
		color: #666;
	}

	.status-item .value {
		color: #333;
		font-family: monospace;
		background: #f5f5f5;
		padding: 4px 8px;
		border-radius: 4px;
	}

	.refresh-btn {
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		color: white;
		border: none;
		padding: 10px 20px;
		border-radius: 6px;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.3s;
		white-space: nowrap;
	}

	.refresh-btn:hover:not(:disabled) {
		transform: translateY(-2px);
		box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);
	}

	.refresh-btn:disabled {
		opacity: 0.6;
		cursor: not-allowed;
	}

	.search-section {
		margin-bottom: 20px;
		display: flex;
		gap: 10px;
		align-items: center;
	}

	.search-input {
		flex: 1;
		padding: 12px;
		border: 2px solid #ddd;
		border-radius: 6px;
		font-size: 1rem;
		transition: border-color 0.3s;
	}

	.search-input:focus {
		outline: none;
		border-color: #667eea;
	}

	.search-info {
		color: #666;
		font-size: 0.9rem;
		white-space: nowrap;
	}

	.loading {
		text-align: center;
		padding: 60px 20px;
	}

	.spinner {
		width: 40px;
		height: 40px;
		border: 4px solid #f3f3f3;
		border-top: 4px solid #667eea;
		border-radius: 50%;
		animation: spin 1s linear infinite;
		margin: 0 auto 20px;
	}

	@keyframes spin {
		0% { transform: rotate(0deg); }
		100% { transform: rotate(360deg); }
	}

	.rates-table {
		background: white;
		border-radius: 8px;
		overflow: hidden;
		box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
	}

	table {
		width: 100%;
		border-collapse: collapse;
	}

	thead {
		background: #f8f8f8;
		border-bottom: 2px solid #ddd;
	}

	th {
		padding: 15px;
		text-align: left;
		font-weight: 600;
		color: #333;
	}

	td {
		padding: 12px 15px;
		border-bottom: 1px solid #eee;
	}

	.rate-row:hover {
		background: #f9f9f9;
	}

	.currency-code {
		font-weight: 600;
		font-family: monospace;
		color: #667eea;
	}

	.rate-value {
		font-family: monospace;
		color: #333;
		text-align: right;
		padding-right: 20px;
	}

	.timestamp {
		color: #666;
		font-size: 0.9rem;
	}

	.date-retrieved {
		color: #999;
		font-size: 0.9rem;
	}

	.empty-state {
		text-align: center;
		padding: 60px 20px;
		color: #666;
	}

	.empty-state p {
		margin: 0 0 10px 0;
	}

	.empty-state .hint {
		color: #999;
		font-size: 0.9rem;
	}

	@media (max-width: 768px) {
		.status-panel {
			flex-direction: column;
			align-items: stretch;
		}

		.search-section {
			flex-direction: column;
		}

		.search-info {
			white-space: normal;
		}

		table {
			font-size: 0.9rem;
		}

		th, td {
			padding: 10px 8px;
		}
	}
</style>
