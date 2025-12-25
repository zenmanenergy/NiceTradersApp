<script>
	export let translationKey = null;
	export let languages = [];

	let translations = {};
	let loading = false;
	let error = null;
	let success = null;
	let editingLang = null;
	let editValues = {};
	let currentKey = null;

	$: if (translationKey && translationKey !== currentKey) {
		currentKey = translationKey;
		loadTranslations();
	}

	async function loadTranslations() {
		loading = true;
		error = null;
		try {
			const response = await fetch(`/Admin/Translations/GetDetails?key=${encodeURIComponent(currentKey)}`);
			const data = await response.json();

			if (data.success) {
				translations = data.translations;
			} else {
				error = data.message;
			}
		} catch (e) {
			error = `Failed to load translations: ${e.message}`;
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

	function startEditing(lang) {
		editingLang = lang;
		editValues[lang] = translations[lang]?.value || '';
	}

	function cancelEditing() {
		editingLang = null;
		editValues = {};
	}

	async function saveTranslation(lang) {
		if (!editValues[lang]?.trim()) {
			error = 'Translation value cannot be empty';
			return;
		}

		try {
			const response = await fetch('/Admin/Translations/BulkUpdate', {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({
					updates: [
						{
							translationKey: currentKey,
							languageCode: lang,
							translationValue: editValues[lang]
						}
					]
				})
			});

			const data = await response.json();

			if (data.success) {
				translations[lang] = {
					value: editValues[lang],
					lastModified: new Date().toISOString()
				};
				editingLang = null;
				success = `✓ Updated ${getLanguageName(lang)}`;

				setTimeout(() => {
					success = null;
				}, 3000);
			} else {
				error = data.message;
			}
		} catch (e) {
			error = `Failed to save: ${e.message}`;
		}
	}

	function getCompletionStatus(lang) {
		if (lang === 'en') return 'complete';
		const trans = translations[lang];
		if (!trans) return 'missing';
		if (!trans.value || trans.value.trim() === '') return 'empty';
		return 'complete';
	}

	function getStatusColor(status) {
		switch (status) {
			case 'complete':
				return '#3c3';
			case 'empty':
				return '#fc3';
			case 'missing':
				return '#c33';
			default:
				return '#999';
		}
	}
</script>

<div class="language-translator">
	<div class="translator-header">
		<h2>Translations</h2>
		<span class="lang-count">{languages.length} languages</span>
	</div>

	{#if loading}
		<div class="loading">Loading translations...</div>
	{:else}
		<div class="translator-content">
			{#if error}
				<div class="error-box">{error}</div>
			{/if}

			{#if success}
				<div class="success-box">{success}</div>
			{/if}

			<div class="languages-grid">
				{#each languages as lang}
					<div class="language-card">
						<div class="lang-header">
							<span class="lang-name">{getLanguageName(lang)}</span>
							<span
								class="status-dot"
								style="background-color: {getStatusColor(getCompletionStatus(lang))}"
								title={getCompletionStatus(lang)}
							/>
						</div>

						{#if editingLang === lang}
							<!-- Edit mode -->
							<textarea
								bind:value={editValues[lang]}
								placeholder="Enter {getLanguageName(lang)}"
								rows="4"
								class="translation-textarea"
							/>
							<div class="edit-buttons">
								<button
									class="btn btn-save"
									on:click={() => saveTranslation(lang)}
								>
									Save
								</button>
								<button
									class="btn btn-cancel"
									on:click={cancelEditing}
								>
									Cancel
								</button>
							</div>
						{:else}
							<!-- View mode -->
							<div
								class="translation-value"
								class:empty={!translations[lang]?.value}
								class:english={lang === 'en'}
							>
								{translations[lang]?.value || '(not translated)'}
							</div>

							<div class="meta-info">
								{#if translations[lang]?.lastModified}
									<small>
										Updated {new Date(
											translations[lang].lastModified
										).toLocaleDateString()}
									</small>
								{/if}
							</div>

							{#if lang !== 'en'}
								<button
									class="btn btn-edit"
									on:click={() => startEditing(lang)}
								>
									Edit
								</button>
							{/if}
						{/if}
					</div>
				{/each}
			</div>
		</div>
	{/if}
</div>

<style>
	.language-translator {
		display: flex;
		flex-direction: column;
		height: 100%;
		background: white;
		overflow-y: auto;
	}

	.translator-header {
		padding: 20px;
		border-bottom: 2px solid #0066cc;
		flex-shrink: 0;
		display: flex;
		align-items: center;
		justify-content: space-between;
	}

	.translator-header h2 {
		margin: 0;
		font-size: 18px;
		color: #333;
	}

	.lang-count {
		background: #e8f4ff;
		color: #0066cc;
		padding: 6px 12px;
		border-radius: 4px;
		font-size: 12px;
		font-weight: bold;
	}

	.loading {
		padding: 40px 20px;
		text-align: center;
		color: #999;
	}

	.translator-content {
		padding: 20px;
		flex: 1;
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

	.success-box {
		background: #efe;
		color: #3c3;
		padding: 12px 15px;
		border-radius: 4px;
		border-left: 4px solid #3c3;
		margin-bottom: 20px;
		font-size: 13px;
	}

	.languages-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
		gap: 15px;
	}

	.language-card {
		border: 1px solid #ddd;
		border-radius: 6px;
		padding: 15px;
		background: #fafafa;
		transition: all 0.2s;
	}

	.language-card:hover {
		border-color: #0066cc;
		background: white;
		box-shadow: 0 2px 8px rgba(0, 102, 204, 0.1);
	}

	.lang-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 12px;
	}

	.lang-name {
		font-weight: 600;
		font-size: 14px;
		color: #333;
	}

	.status-dot {
		display: inline-block;
		width: 10px;
		height: 10px;
		border-radius: 50%;
		flex-shrink: 0;
	}

	.translation-textarea {
		width: 100%;
		padding: 10px;
		border: 1px solid #ddd;
		border-radius: 4px;
		font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
		font-size: 13px;
		line-height: 1.5;
		box-sizing: border-box;
		resize: vertical;
		margin-bottom: 10px;
	}

	.translation-textarea:focus {
		outline: none;
		border-color: #0066cc;
		box-shadow: 0 0 0 3px rgba(0, 102, 204, 0.1);
	}

	.translation-value {
		padding: 12px;
		background: white;
		border-radius: 4px;
		border: 1px solid #e0e0e0;
		font-size: 13px;
		line-height: 1.5;
		margin-bottom: 10px;
		min-height: 60px;
		color: #333;
		word-break: break-word;
	}

	.translation-value.empty {
		color: #999;
		font-style: italic;
		background: #fff9f9;
		border-color: #f0d0d0;
	}

	.translation-value.english {
		background: #f0f8ff;
		border-color: #0066cc;
		font-weight: 500;
	}

	.meta-info {
		font-size: 11px;
		color: #999;
		margin-bottom: 10px;
	}

	.edit-buttons {
		display: flex;
		gap: 8px;
	}

	.btn {
		flex: 1;
		padding: 8px 12px;
		border: none;
		border-radius: 4px;
		font-size: 12px;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.2s;
	}

	.btn-edit {
		width: 100%;
		background: #0066cc;
		color: white;
	}

	.btn-edit:hover {
		background: #0052a3;
	}

	.btn-save {
		background: #3c3;
		color: white;
	}

	.btn-save:hover {
		background: #2a2;
	}

	.btn-cancel {
		background: #f0f0f0;
		color: #333;
	}

	.btn-cancel:hover {
		background: #e0e0e0;
	}
</style>
