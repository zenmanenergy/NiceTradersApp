<script>
	import SuperFetch from '../../SuperFetch.js';
	import AdminHeader from '$lib/AdminHeader.svelte';
	import AdminLayout from '$lib/AdminLayout.svelte';
	import { onMount } from 'svelte';

	let logType = 'flask';
	let lines = 100;
	let search = '';
	let logs = '';
	let loading = false;
	let error = null;
	let metadata = null;
	let autoRefresh = false;
	let refreshInterval = null;
	let debugInfo = null;
	
	onMount(() => {
		loadLogs();
	});
	
	async function loadLogs() {
		loading = true;
		error = null;
		
		try {
			const response = await SuperFetch('/Admin/GetLogs', {
				type: logType,
				lines: lines,
				search: search
			});
			
			console.log('GetLogs response:', response);
			
			// Store debug info
			debugInfo = {
				success: response.success,
				hasLogs: !!response.logs,
				logsLength: response.logs ? response.logs.length : 0,
				error: response.error
			};
			
			if (response.success) {
				logs = response.logs;
				metadata = {
					total_lines: response.total_lines,
					returned_lines: response.returned_lines,
					file_size_bytes: response.file_size_bytes,
					last_modified: response.last_modified,
					log_file: response.log_file
				};
			} else {
				error = response.error || 'Failed to load logs';
				logs = '';
			}
		} catch (err) {
			console.error('Error loading logs:', err);
			error = err.message || 'Network error loading logs';
			logs = '';
		} finally {
			loading = false;
		}
	}
	
	async function clearLogs() {
		if (!confirm(`Are you sure you want to clear the ${logType} logs? This cannot be undone.`)) {
			return;
		}
		
		loading = true;
		error = null;
		
		try {
			const response = await SuperFetch('/Admin/ClearLogs', {
				type: logType
			}, 'POST');
			
			if (response.success) {
				logs = '';
				await loadLogs();
			} else {
				error = response.error || 'Failed to clear logs';
			}
		} catch (err) {
			error = err.message;
		} finally {
			loading = false;
		}
	}
	
	function toggleAutoRefresh() {
		autoRefresh = !autoRefresh;
		
		if (autoRefresh) {
			refreshInterval = setInterval(() => {
				loadLogs();
			}, 3000); // Refresh every 3 seconds
		} else {
			if (refreshInterval) {
				clearInterval(refreshInterval);
				refreshInterval = null;
			}
		}
	}
	
	function formatBytes(bytes) {
		if (bytes === 0) return '0 Bytes';
		const k = 1024;
		const sizes = ['Bytes', 'KB', 'MB', 'GB'];
		const i = Math.floor(Math.log(bytes) / Math.log(k));
		return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
	}
	
	function formatDate(isoDate) {
		if (!isoDate) return '-';
		try {
			const date = new Date(isoDate);
			return date.toLocaleString();
		} catch {
			return isoDate;
		}
	}
	
	// Load logs on mount
	// (moved to onMount hook above)
</script>

<AdminHeader />

<AdminLayout>
	<div class="logs-view">
		<div class="logs-header">
			<h2>📋 Server Logs</h2>
		</div>
	
	<div class="controls-panel">
		<div class="control-group">
			<label>Log Type:</label>
			<select bind:value={logType} on:change={loadLogs}>
				<option value="flask">Flask Application</option>
				<option value="error">Error Log</option>
			</select>
		</div>
		
		<div class="control-group">
			<label>Lines:</label>
			<select bind:value={lines} on:change={loadLogs}>
				<option value="50">50</option>
				<option value="100">100</option>
				<option value="250">250</option>
				<option value="500">500</option>
				<option value="1000">1000</option>
			</select>
		</div>
		
		<div class="control-group search-group">
			<label>Search:</label>
			<input 
				type="text" 
				bind:value={search} 
				on:input={loadLogs}
				placeholder="Filter logs..."
			/>
		</div>
		
		<div class="control-buttons">
			<button class="refresh-btn" on:click={loadLogs} disabled={loading}>
				{loading ? '⏳ Loading...' : '🔄 Refresh'}
			</button>
			
			<button 
				class="auto-refresh-btn {autoRefresh ? 'active' : ''}" 
				on:click={toggleAutoRefresh}
			>
				{autoRefresh ? '⏸ Stop Auto' : '▶ Auto Refresh'}
			</button>
			
			<button class="clear-btn" on:click={clearLogs} disabled={loading}>
				🗑️ Clear Logs
			</button>
		</div>
	</div>
	
	{#if metadata}
		<div class="metadata-panel">
			<span><strong>File:</strong> {metadata.log_file}</span>
			<span><strong>Total Lines:</strong> {metadata.total_lines.toLocaleString()}</span>
			<span><strong>Showing:</strong> {metadata.returned_lines.toLocaleString()}</span>
			<span><strong>Size:</strong> {formatBytes(metadata.file_size_bytes)}</span>
			<span><strong>Modified:</strong> {formatDate(metadata.last_modified)}</span>
		</div>
	{/if}
	
	{#if debugInfo}
		<div class="debug-panel">
			<strong>Debug:</strong>
			Success: {debugInfo.success ? '✓' : '✗'} |
			Has Logs: {debugInfo.hasLogs ? 'Yes' : 'No'} |
			Length: {debugInfo.logsLength} chars
			{#if debugInfo.error}
				| Error: {debugInfo.error}
			{/if}
		</div>
	{/if}
	
	{#if error}
		<div class="error-message">
			❌ {error}
		</div>
	{/if}
	
	<div class="logs-container">
		{#if loading && !logs}
			<div class="loading-state">
				⏳ Loading logs...
			</div>
		{:else if logs}
			<pre class="logs-content">{logs}</pre>
		{:else}
			<div class="empty-state">
				{#if error}
					Check error message above
				{:else}
					No logs available or log file is empty
				{/if}
			</div>
		{/if}
	</div>
</div>
</AdminLayout>

<style>
	.logs-view {
		background: white;
		padding: 30px;
		border-radius: 12px;
		box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
	}

	.logs-header {
		margin-bottom: 20px;
		padding-bottom: 15px;
		border-bottom: 2px solid #f0f0f0;
	}

	.logs-header h2 {
		margin: 0;
		color: #333;
	}

	.controls-panel {
		display: flex;
		gap: 16px;
		flex-wrap: wrap;
		align-items: flex-end;
		margin-bottom: 20px;
		padding: 20px;
		background: #f8f9fa;
		border-radius: 8px;
	}

	.control-group {
		display: flex;
		flex-direction: column;
		gap: 6px;
	}

	.control-group label {
		font-weight: 600;
		font-size: 0.9rem;
		color: #555;
	}

	.control-group select,
	.control-group input {
		padding: 8px 12px;
		border: 1px solid #cbd5e0;
		border-radius: 6px;
		font-size: 0.95rem;
		background: white;
	}

	.search-group {
		flex: 1;
		min-width: 200px;
	}

	.search-group input {
		width: 100%;
	}

	.control-buttons {
		display: flex;
		gap: 10px;
		flex-wrap: wrap;
	}

	.control-buttons button {
		padding: 8px 16px;
		border: none;
		border-radius: 6px;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.2s;
		font-size: 0.9rem;
	}

	.refresh-btn {
		background: #667eea;
		color: white;
	}

	.refresh-btn:hover:not(:disabled) {
		background: #5568d3;
	}

	.auto-refresh-btn {
		background: #48bb78;
		color: white;
	}

	.auto-refresh-btn.active {
		background: #ed8936;
	}

	.auto-refresh-btn:hover {
		opacity: 0.9;
	}

	.clear-btn {
		background: #fc8181;
		color: white;
	}

	.clear-btn:hover:not(:disabled) {
		background: #f56565;
	}

	button:disabled {
		opacity: 0.5;
		cursor: not-allowed;
	}

	.metadata-panel {
		display: flex;
		gap: 20px;
		flex-wrap: wrap;
		padding: 12px 16px;
		background: #edf2f7;
		border-radius: 6px;
		margin-bottom: 16px;
		font-size: 0.85rem;
		color: #555;
	}

	.metadata-panel span {
		white-space: nowrap;
	}

	.metadata-panel strong {
		color: #333;
	}

	.debug-panel {
		padding: 10px 16px;
		background: #fff3cd;
		border: 1px solid #ffc107;
		border-radius: 6px;
		margin-bottom: 16px;
		font-size: 0.85rem;
		color: #856404;
		font-family: monospace;
	}

	.error-message {
		padding: 12px 16px;
		background: #fed7d7;
		border: 1px solid #fc8181;
		border-radius: 6px;
		color: #c53030;
		margin-bottom: 16px;
	}

	.logs-container {
		background: #1e1e1e;
		border-radius: 8px;
		overflow: hidden;
		border: 1px solid #e2e8f0;
	}

	.logs-content {
		margin: 0;
		padding: 20px;
		color: #d4d4d4;
		font-family: 'Monaco', 'Courier New', monospace;
		font-size: 0.85rem;
		line-height: 1.5;
		overflow-x: auto;
		white-space: pre-wrap;
		word-wrap: break-word;
		max-height: 600px;
		overflow-y: auto;
	}

	.empty-state {
		padding: 60px 20px;
		text-align: center;
		color: #999;
		font-style: italic;
	}

	.loading-state {
		padding: 60px 20px;
		text-align: center;
		color: #667eea;
		font-size: 1.1rem;
	}

	@media (max-width: 768px) {
		.controls-panel {
			flex-direction: column;
			align-items: stretch;
		}

		.control-buttons {
			flex-direction: column;
		}

		.control-buttons button {
			width: 100%;
		}

		.metadata-panel {
			flex-direction: column;
			gap: 8px;
		}
	}
</style>
