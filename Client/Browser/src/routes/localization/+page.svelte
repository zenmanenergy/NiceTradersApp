<script>
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import { goto } from '$app/navigation';
	import { Settings } from '../../Settings.js';
	import ViewList from './ViewList.svelte';
	import EnglishEditor from './EnglishEditor.svelte';
	import LanguageTranslator from './LanguageTranslator.svelte';

	let viewInventory = null;
	let selectedKey = null;
	let selectedView = null;
	let loading = false;
	let error = null;
	let stats = null;
	let activeTab = 'editor'; // editor, history, status
	let debugInfo = null;
	let englishValue = ''; // Track English value for auto-translate
	const API_BASE = Settings.baseURL;

	onMount(async () => {
		console.log('🔍 Localization Editor mounted, checking inventory status...');
		console.log(`📡 API Base URL: ${API_BASE}`);
		await checkInventoryStatus();
		await loadViewInventory();
	});

	async function checkInventoryStatus() {
		try {
			const url = `${API_BASE}/Admin/Translations/CheckInventoryStatus`;
			console.log(`📊 Checking inventory status at: ${url}`);
			const response = await fetch(url);
			const data = await response.json();
			debugInfo = data;
			console.log('📋 Inventory Status:', data);
		} catch (e) {
			console.log('⚠️  Could not check inventory status:', e);
		}
	}

	async function loadViewInventory() {
		loading = true;
		error = null;
		try {
			const url = `${API_BASE}/Admin/Translations/GetViewInventory`;
			console.log(`📥 Loading inventory from: ${url}`);
			const response = await fetch(url);
			
			// Debug: Log response status and type
			console.log('=== Inventory Load Debug ===');
			console.log('Status:', response.status);
			console.log('Content-Type:', response.headers.get('content-type'));
			
			const text = await response.text();
			console.log('Response (first 500 chars):', text.substring(0, 500));
			
			// Try to parse as JSON
			let data;
			try {
				data = JSON.parse(text);
			} catch (parseErr) {
				console.error('JSON Parse Error:', parseErr.message);
				console.error('Response started with:', text.substring(0, 100));
				error = `Invalid JSON response: ${parseErr.message}. Response: ${text.substring(0, 200)}`;
				loading = false;
				return;
			}

			if (data.success) {
				viewInventory = data;
				stats = {
					totalViews: data.totalViews,
					totalKeys: data.totalKeys,
					languages: data.languages.length
				};
				console.log('✅ Inventory loaded successfully');
			} else {
				error = data.message || 'Unknown error loading inventory';
				console.error('❌ Server returned error:', data.message);
				if (data.debug) {
					console.error('Server debug info:', data.debug);
				}
			}
		} catch (e) {
			error = `Failed to load inventory: ${e.message}`;
			console.error('❌ Fetch error:', e);
		}
		loading = false;
	}

	function handleViewSelected(event) {
		selectedView = event.detail;
		// Select first key from view if available
		if (selectedView.translationKeys.length > 0) {
			selectedKey = selectedView.translationKeys[0];
		}
	}

	function handleKeySelected(event) {
		selectedKey = event.detail;
	}

	function handleEnglishUpdated() {
		// Refresh details when English is updated
		if (selectedKey) {
			// Trigger refresh in LanguageTranslator
		}
	}

	function handleEnglishValueChange(event) {
		englishValue = event.detail;
	}

	function switchTab(tab) {
		activeTab = tab;
		if (tab === 'status') {
			goto('/localization/status');
		}
	}
</script>

<div class="localization-editor">
	<header class="editor-header">
		<h1>🌐 Localization Editor</h1>
		<div class="stats">
			{#if stats}
				<span class="stat-item">
					<strong>{stats.totalViews}</strong> Views
				</span>
				<span class="stat-item">
					<strong>{stats.totalKeys}</strong> Translation Keys
				</span>
				<span class="stat-item">
					<strong>{stats.languages}</strong> Languages
				</span>
			{/if}
			<button class="btn-refresh" on:click={loadViewInventory} disabled={loading}>
				{loading ? '⟳ Loading...' : '⟳ Refresh'}
			</button>
		</div>

		<!-- Tabs -->
		<div class="tabs">
			<button 
				class="tab" 
				class:active={activeTab === 'editor'}
				on:click={() => switchTab('editor')}
			>
				✎ Editor
			</button>
			<button 
				class="tab" 
				class:active={activeTab === 'status'}
				on:click={() => switchTab('status')}
			>
				📊 Status
			</button>
		</div>
	</header>

	{#if error}
		<div class="error-message">
			<strong>Error:</strong> {error}
			<details style="margin-top: 10px; padding-top: 10px; border-top: 1px solid #ddd;">
				<summary style="cursor: pointer; font-weight: 600; color: #666;">Debug Info</summary>
				<pre style="background: #f5f5f5; padding: 10px; border-radius: 4px; font-size: 12px; overflow-x: auto;">Check browser console (F12) for detailed debug logs</pre>
			</details>
		</div>
	{/if}

	{#if loading && !viewInventory}
		<div class="loading-message">Loading inventory...</div>
	{:else if viewInventory}
		<div class="editor-container">
			<!-- Left Panel: View and Key List -->
			<div class="panel left-panel">
				<ViewList
					views={viewInventory.views}
					selectedKey={selectedKey}
					on:viewSelected={handleViewSelected}
					on:keySelected={handleKeySelected}
				/>
			</div>

			<!-- Middle Panel: English Editor -->
			{#if selectedKey}
				<div class="panel middle-panel">
					<EnglishEditor
						translationKey={selectedKey}
						on:updated={handleEnglishUpdated}
						on:englishValueChanged={handleEnglishValueChange}
					/>
				</div>

				<!-- Right Panel: Language Translations -->
				<div class="panel right-panel">
					<LanguageTranslator
						translationKey={selectedKey}
						languages={viewInventory.languages}
						englishValue={englishValue}
					/>
				</div>
			{:else}
				<div class="panel middle-panel">
					<div class="placeholder">
						<p>Select a translation key to get started</p>
					</div>
				</div>
			{/if}
		</div>
	{/if}
</div>

<style>
	.localization-editor {
		height: 100vh;
		display: flex;
		flex-direction: column;
		background-color: #f5f5f5;
	}

	.editor-header {
		background: white;
		border-bottom: 1px solid #e0e0e0;
		padding: 20px;
		box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
	}

	.editor-header h1 {
		margin: 0 0 15px 0;
		font-size: 28px;
		color: #333;
	}

	.tabs {
		display: flex;
		gap: 10px;
		margin-top: 15px;
		border-bottom: 2px solid #e0e0e0;
	}

	.tab {
		padding: 10px 20px;
		background: none;
		border: none;
		border-bottom: 3px solid transparent;
		color: #666;
		font-size: 14px;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.2s;
	}

	.tab:hover {
		color: #0066cc;
	}

	.tab.active {
		color: #0066cc;
		border-bottom-color: #0066cc;
	}

	.stats {
		display: flex;
		gap: 20px;
		align-items: center;
		flex-wrap: wrap;
	}

	.stat-item {
		display: flex;
		align-items: center;
		gap: 8px;
		padding: 8px 15px;
		background: #f9f9f9;
		border-radius: 4px;
		font-size: 14px;
	}

	.stat-item strong {
		color: #0066cc;
		font-size: 16px;
	}

	.btn-refresh {
		padding: 8px 15px;
		background: #0066cc;
		color: white;
		border: none;
		border-radius: 4px;
		cursor: pointer;
		font-size: 14px;
		transition: background 0.2s;
	}

	.btn-refresh:hover:not(:disabled) {
		background: #0052a3;
	}

	.btn-refresh:disabled {
		opacity: 0.6;
		cursor: not-allowed;
	}

	.error-message {
		background: #fee;
		color: #c33;
		padding: 15px 20px;
		border-left: 4px solid #c33;
		font-size: 14px;
	}

	.loading-message {
		text-align: center;
		padding: 40px;
		color: #666;
		font-size: 16px;
	}

	.editor-container {
		display: flex;
		flex: 1;
		gap: 1px;
		overflow: hidden;
		background: #ddd;
	}

	.panel {
		background: white;
		overflow-y: auto;
		border-right: 1px solid #ddd;
	}

	.left-panel {
		flex: 0 0 300px;
		border-right: 1px solid #ddd;
	}

	.middle-panel {
		flex: 1;
		min-width: 400px;
	}

	.right-panel {
		flex: 1;
		min-width: 400px;
		border-right: none;
	}

	.placeholder {
		display: flex;
		align-items: center;
		justify-content: center;
		height: 100%;
		color: #999;
		font-size: 16px;
	}

	@media (max-width: 1400px) {
		.right-panel {
			display: none;
		}
	}

	@media (max-width: 900px) {
		.editor-container {
			flex-direction: column;
		}

		.left-panel,
		.middle-panel,
		.right-panel {
			flex: none;
			border-right: none;
			border-bottom: 1px solid #ddd;
		}

		.left-panel {
			height: 200px;
		}

		.middle-panel {
			height: 300px;
		}

		.right-panel {
			display: block;
			height: 300px;
		}
	}
</style>
