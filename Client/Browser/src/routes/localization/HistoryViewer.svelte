<script>
	import { onMount } from 'svelte';

	export let translationKey = null;

	let history = [];
	let loading = false;
	let error = null;
	let selectedLanguage = null;
	let languages = ['en', 'ja', 'es', 'fr', 'de', 'ar', 'hi', 'pt', 'ru', 'sk', 'zh'];

	onMount(async () => {
		selectedLanguage = 'en';
		await loadHistory();
	});

	async function loadHistory() {
		if (!translationKey || !selectedLanguage) return;

		loading = true;
		error = null;

		try {
			const response = await fetch(
				`/Admin/Translations/GetHistory?key=${encodeURIComponent(translationKey)}&language=${selectedLanguage}`
			);
			const data = await response.json();

			if (data.success) {
				history = data.history || [];
			} else {
				error = data.message;
			}
		} catch (e) {
			error = `Failed to load history: ${e.message}`;
		}

		loading = false;
	}

	async function handleRollback(historyId) {
		if (!confirm('Are you sure you want to rollback this translation?')) {
			return;
		}

		try {
			const response = await fetch('/Admin/Translations/RollbackTranslation', {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({
					translationKey: translationKey,
					languageCode: selectedLanguage,
					historyId: historyId
				})
			});

			const data = await response.json();

			if (data.success) {
				// Reload history
				await loadHistory();
				// Show success message
				alert(`✓ ${data.message}`);
			} else {
				alert(`Error: ${data.message}`);
			}
		} catch (e) {
			alert(`Failed to rollback: ${e.message}`);
		}
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

	function formatDate(dateString) {
		if (!dateString) return 'Unknown';
		const date = new Date(dateString);
		return date.toLocaleString();
	}

	$: if (translationKey) {
		loadHistory();
	}
</script>

<div class="history-viewer">
	<div class="viewer-header">
		<h2>Change History</h2>
		<p class="key-name">{translationKey}</p>
	</div>

	<div class="language-selector">
		<label>Show history for:</label>
		<select bind:value={selectedLanguage} on:change={loadHistory}>
			{#each languages as lang}
				<option value={lang}>{getLanguageName(lang)}</option>
			{/each}
		</select>
	</div>

	{#if error}
		<div class="error-box">{error}</div>
	{/if}

	{#if loading}
		<div class="loading">Loading history...</div>
	{:else if history.length === 0}
		<div class="no-history">No change history available</div>
	{:else}
		<div class="history-list">
			{#each history as record}
				<div class="history-item">
					<div class="history-header">
						<span class="change-reason">{record.change_reason}</span>
						<span class="change-date">{formatDate(record.changed_at)}</span>
					</div>

					<div class="change-content">
						{#if record.old_value}
							<div class="change-section">
								<span class="label">From:</span>
								<div class="old-value">
									{record.old_value}
								</div>
							</div>
						{/if}

						{#if record.new_value}
							<div class="change-section">
								<span class="label">To:</span>
								<div class="new-value">
									{record.new_value}
								</div>
							</div>
						{/if}
					</div>

					<div class="history-footer">
						{#if record.changed_by}
							<span class="by-user">Changed by user #{record.changed_by}</span>
						{/if}
						<button
							class="btn-rollback"
							on:click={() => handleRollback(record.id)}
						>
							↶ Rollback
						</button>
					</div>
				</div>
			{/each}
		</div>
	{/if}
</div>

<style>
	.history-viewer {
		padding: 20px;
		background: white;
		border-radius: 6px;
	}

	.viewer-header {
		margin-bottom: 20px;
		padding-bottom: 15px;
		border-bottom: 2px solid #0066cc;
	}

	.viewer-header h2 {
		margin: 0 0 8px 0;
		font-size: 18px;
		color: #333;
	}

	.key-name {
		margin: 0;
		font-family: 'Monaco', 'Menlo', monospace;
		font-size: 12px;
		color: #0066cc;
		background: #e8f4ff;
		display: inline-block;
		padding: 4px 8px;
		border-radius: 3px;
	}

	.language-selector {
		margin-bottom: 20px;
		display: flex;
		align-items: center;
		gap: 10px;
	}

	.language-selector label {
		font-weight: 600;
		font-size: 14px;
		color: #333;
	}

	.language-selector select {
		padding: 8px 12px;
		border: 1px solid #ddd;
		border-radius: 4px;
		font-size: 14px;
		background: white;
	}

	.language-selector select:focus {
		outline: none;
		border-color: #0066cc;
		box-shadow: 0 0 0 3px rgba(0, 102, 204, 0.1);
	}

	.error-box {
		background: #fee;
		color: #c33;
		padding: 12px 15px;
		border-radius: 4px;
		border-left: 4px solid #c33;
		margin-bottom: 20px;
		font-size: 13px;
	}

	.loading,
	.no-history {
		text-align: center;
		padding: 40px 20px;
		color: #999;
		font-size: 14px;
	}

	.history-list {
		display: flex;
		flex-direction: column;
		gap: 15px;
	}

	.history-item {
		border: 1px solid #ddd;
		border-radius: 6px;
		overflow: hidden;
		background: #fafafa;
		transition: all 0.2s;
	}

	.history-item:hover {
		border-color: #0066cc;
		background: white;
		box-shadow: 0 2px 8px rgba(0, 102, 204, 0.1);
	}

	.history-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		padding: 12px 15px;
		background: #f5f5f5;
		border-bottom: 1px solid #ddd;
	}

	.change-reason {
		font-weight: 600;
		color: #333;
		font-size: 13px;
	}

	.change-date {
		font-size: 12px;
		color: #999;
	}

	.change-content {
		padding: 15px;
	}

	.change-section {
		margin-bottom: 12px;
	}

	.change-section:last-child {
		margin-bottom: 0;
	}

	.label {
		display: block;
		font-weight: 600;
		font-size: 12px;
		color: #666;
		margin-bottom: 6px;
		text-transform: uppercase;
	}

	.old-value,
	.new-value {
		padding: 10px 12px;
		border-radius: 4px;
		font-size: 12px;
		line-height: 1.5;
		font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', monospace;
		word-break: break-word;
	}

	.old-value {
		background: #ffc0c0;
		color: #8b0000;
	}

	.new-value {
		background: #c0ffc0;
		color: #008b00;
	}

	.history-footer {
		display: flex;
		justify-content: space-between;
		align-items: center;
		padding: 10px 15px;
		background: #f5f5f5;
		border-top: 1px solid #ddd;
	}

	.by-user {
		font-size: 11px;
		color: #999;
	}

	.btn-rollback {
		padding: 6px 12px;
		background: #f0a0a0;
		color: #8b0000;
		border: none;
		border-radius: 3px;
		font-size: 12px;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.2s;
	}

	.btn-rollback:hover {
		background: #f08080;
	}
</style>
