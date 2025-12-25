<script>
	import { onMount } from 'svelte';

	let stats = null;
	let loading = false;
	let error = null;
	let validationResults = null;

	onMount(async () => {
		await loadStats();
	});

	async function loadStats() {
		loading = true;
		error = null;

		try {
			const response = await fetch('/Admin/Translations/GetViewInventory');
			const data = await response.json();

			if (data.success) {
				stats = {
					totalViews: data.totalViews,
					totalKeys: data.totalKeys,
					supportedLanguages: data.languages.length,
					languages: data.languages
				};

				// Calculate coverage
				calculateCoverage(data);
			} else {
				error = data.message;
			}
		} catch (e) {
			error = `Failed to load stats: ${e.message}`;
		}

		loading = false;
	}

	function calculateCoverage(data) {
		// This would be enhanced with actual data from the inventory
		const coverage = {};
		data.languages.forEach((lang) => {
			coverage[lang] = Math.random() * 100; // Placeholder
		});
		stats.coverage = coverage;
	}

	async function handleValidate() {
		loading = true;
		error = null;

		try {
			const response = await fetch('/Admin/Translations/ValidateKeys', {
				method: 'POST'
			});
			const data = await response.json();

			if (data.success) {
				validationResults = data;
			} else {
				error = data.message;
			}
		} catch (e) {
			error = `Failed to validate: ${e.message}`;
		}

		loading = false;
	}

	async function handleScan() {
		loading = true;
		error = null;

		try {
			const response = await fetch('/Admin/Translations/ScanCodeForKeys', {
				method: 'POST'
			});
			const data = await response.json();

			if (data.success) {
				alert('✓ Code scan completed successfully');
				await loadStats();
			} else {
				error = data.message;
			}
		} catch (e) {
			error = `Failed to scan: ${e.message}`;
		}

		loading = false;
	}

	function getLanguageName(code) {
		const names = {
			en: '🇬🇧 English',
			ja: '🇯🇵 Japanese',
			es: '🇪🇸 Spanish',
			fr: '🇫🇷 French',
			de: '🇩🇪 German',
			ar: '🇸🇦 Arabic',
			hi: '🇮🇳 Hindi',
			pt: '🇵🇹 Portuguese',
			ru: '🇷🇺 Russian',
			sk: '🇸🇰 Slovak',
			zh: '🇨🇳 Chinese'
		};
		return names[code] || code;
	}
</script>

<div class="status-dashboard">
	<header class="dashboard-header">
		<h1>📊 Translation Status Dashboard</h1>
		<div class="actions">
			<button class="btn btn-primary" on:click={handleValidate} disabled={loading}>
				{loading ? 'Validating...' : '✓ Validate Keys'}
			</button>
			<button class="btn btn-secondary" on:click={handleScan} disabled={loading}>
				{loading ? 'Scanning...' : '⟳ Scan Code'}
			</button>
		</div>
	</header>

	{#if error}
		<div class="error-message">{error}</div>
	{/if}

	{#if loading && !stats}
		<div class="loading-message">Loading statistics...</div>
	{:else if stats}
		<div class="stats-grid">
			<!-- Overall Stats -->
			<div class="stat-card">
				<div class="stat-value">{stats.totalKeys}</div>
				<div class="stat-label">Translation Keys</div>
			</div>

			<div class="stat-card">
				<div class="stat-value">{stats.totalViews}</div>
				<div class="stat-label">iOS Views</div>
			</div>

			<div class="stat-card">
				<div class="stat-value">{stats.supportedLanguages}</div>
				<div class="stat-label">Languages</div>
			</div>
		</div>

		<!-- Language Coverage -->
		<div class="section">
			<h2>Language Coverage</h2>
			<div class="language-list">
				{#each stats.languages as lang}
					<div class="language-item">
						<span class="lang-name">{getLanguageName(lang)}</span>
						<div class="progress-bar">
							<div class="progress-fill" style="width: 90%"></div>
						</div>
						<span class="percent">90%</span>
					</div>
				{/each}
			</div>
		</div>

		<!-- Validation Results -->
		{#if validationResults}
			<div class="section validation-results">
				<h2>Validation Results</h2>

				<div class="validation-stats">
					<div class="stat-box">
						<div class="label">Coverage</div>
						<div class="value">{validationResults.validation.coverage}</div>
					</div>
					<div class="stat-box">
						<div class="label">Matched Keys</div>
						<div class="value">{validationResults.validation.matchedKeys}</div>
					</div>
					<div class="stat-box">
						<div class="label">Orphaned Keys</div>
						<div class="value orphaned">{validationResults.validation.orphanedKeys}</div>
					</div>
					<div class="stat-box">
						<div class="label">Missing Keys</div>
						<div class="value missing">{validationResults.validation.missingKeys}</div>
					</div>
				</div>

				{#if validationResults.orphanedKeys.length > 0}
					<div class="key-list orphaned-list">
						<h3>Orphaned Keys (in DB but not used)</h3>
						<ul>
							{#each validationResults.orphanedKeys.slice(0, 10) as key}
								<li>{key}</li>
							{/each}
							{#if validationResults.orphanedKeys.length > 10}
								<li class="more">... and {validationResults.orphanedKeys.length - 10} more</li>
							{/if}
						</ul>
					</div>
				{/if}

				{#if validationResults.missingKeys.length > 0}
					<div class="key-list missing-list">
						<h3>Missing Keys (in code but not in DB)</h3>
						<ul>
							{#each validationResults.missingKeys.slice(0, 10) as key}
								<li>{key}</li>
							{/each}
							{#if validationResults.missingKeys.length > 10}
								<li class="more">... and {validationResults.missingKeys.length - 10} more</li>
							{/if}
						</ul>
					</div>
				{/if}
			</div>
		{/if}
	{/if}
</div>

<style>
	.status-dashboard {
		padding: 30px;
		max-width: 1200px;
	}

	.dashboard-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 30px;
		padding-bottom: 20px;
		border-bottom: 2px solid #0066cc;
	}

	.dashboard-header h1 {
		margin: 0;
		font-size: 28px;
		color: #333;
	}

	.actions {
		display: flex;
		gap: 10px;
	}

	.btn {
		padding: 10px 20px;
		border: none;
		border-radius: 4px;
		font-size: 14px;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.2s;
	}

	.btn-primary {
		background: #0066cc;
		color: white;
	}

	.btn-primary:hover:not(:disabled) {
		background: #0052a3;
	}

	.btn-secondary {
		background: #f0f0f0;
		color: #333;
	}

	.btn-secondary:hover:not(:disabled) {
		background: #e0e0e0;
	}

	.btn:disabled {
		opacity: 0.6;
		cursor: not-allowed;
	}

	.error-message {
		background: #fee;
		color: #c33;
		padding: 15px 20px;
		border-left: 4px solid #c33;
		border-radius: 4px;
		margin-bottom: 20px;
	}

	.loading-message {
		text-align: center;
		padding: 40px;
		color: #999;
	}

	.stats-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
		gap: 20px;
		margin-bottom: 40px;
	}

	.stat-card {
		background: white;
		border: 2px solid #ddd;
		border-radius: 8px;
		padding: 20px;
		text-align: center;
		transition: all 0.2s;
	}

	.stat-card:hover {
		border-color: #0066cc;
		box-shadow: 0 4px 12px rgba(0, 102, 204, 0.2);
	}

	.stat-value {
		font-size: 36px;
		font-weight: bold;
		color: #0066cc;
		margin-bottom: 8px;
	}

	.stat-label {
		font-size: 14px;
		color: #666;
		font-weight: 500;
	}

	.section {
		background: white;
		border: 1px solid #ddd;
		border-radius: 8px;
		padding: 20px;
		margin-bottom: 20px;
	}

	.section h2 {
		margin: 0 0 20px 0;
		font-size: 18px;
		color: #333;
		padding-bottom: 10px;
		border-bottom: 2px solid #0066cc;
	}

	.language-list {
		display: flex;
		flex-direction: column;
		gap: 12px;
	}

	.language-item {
		display: flex;
		align-items: center;
		gap: 15px;
	}

	.lang-name {
		width: 150px;
		font-weight: 500;
		font-size: 14px;
		color: #333;
	}

	.progress-bar {
		flex: 1;
		height: 20px;
		background: #f0f0f0;
		border-radius: 4px;
		overflow: hidden;
	}

	.progress-fill {
		height: 100%;
		background: linear-gradient(90deg, #0066cc, #00cc66);
		transition: width 0.3s;
	}

	.percent {
		width: 50px;
		text-align: right;
		font-size: 12px;
		color: #666;
		font-weight: 600;
	}

	.validation-results {
		border-left: 4px solid #0066cc;
	}

	.validation-stats {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
		gap: 15px;
		margin-bottom: 20px;
	}

	.stat-box {
		background: #f9f9f9;
		padding: 15px;
		border-radius: 4px;
		border-left: 4px solid #0066cc;
	}

	.stat-box .label {
		font-size: 12px;
		color: #666;
		font-weight: 600;
		text-transform: uppercase;
		margin-bottom: 6px;
	}

	.stat-box .value {
		font-size: 24px;
		font-weight: bold;
		color: #0066cc;
	}

	.stat-box .value.orphaned {
		color: #c33;
	}

	.stat-box .value.missing {
		color: #f60;
	}

	.key-list {
		background: #f9f9f9;
		padding: 15px;
		border-radius: 4px;
		margin-bottom: 15px;
	}

	.key-list h3 {
		margin: 0 0 10px 0;
		font-size: 14px;
		color: #333;
	}

	.key-list ul {
		margin: 0;
		padding-left: 20px;
		list-style: none;
	}

	.key-list li {
		padding: 6px 0;
		font-size: 12px;
		color: #666;
		font-family: 'Monaco', 'Menlo', monospace;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
	}

	.key-list li.more {
		color: #999;
		font-style: italic;
	}

	.orphaned-list {
		border-left: 4px solid #c33;
	}

	.missing-list {
		border-left: 4px solid #f60;
	}
</style>
