<script>
	import { createEventDispatcher } from 'svelte';
	import { Settings } from '../../Settings.js';

	export let translationKey = null;

	const dispatch = createEventDispatcher();
	const API_BASE = Settings.baseURL;

	let currentKey = null;
	let englishValue = '';
	let oldEnglishValue = '';
	let updateStrategy = 'manual_review';
	let loading = false;
	let saving = false;
	let error = null;
	let success = null;
	let usedInViews = [];

	$: if (translationKey && translationKey !== currentKey) {
		currentKey = translationKey;
		loadKeyDetails();
	}

	async function loadKeyDetails() {
		loading = true;
		error = null;
		try {
			const url = `${API_BASE}/Admin/Translations/GetDetails?key=${encodeURIComponent(currentKey)}`;
			console.log(`📝 Loading key details from: ${url}`);
			const response = await fetch(url);
			
			const text = await response.text();
			let data;
			try {
				data = JSON.parse(text);
			} catch (parseErr) {
				console.error('JSON Parse Error:', parseErr.message);
				error = `Invalid response: ${parseErr.message}`;
				loading = false;
				return;
			}

			if (data.success) {
				englishValue = data.englishValue || '';
				oldEnglishValue = englishValue;
				usedInViews = data.usedInViews || [];
				dispatch('englishValueChanged', englishValue);
				console.log('✅ Key details loaded');
			} else {
				error = data.message || 'Failed to load';
				englishValue = '';
				oldEnglishValue = '';
				usedInViews = [];
				dispatch('englishValueChanged', '');
				console.error('❌ Server error:', data.message);
			}
		} catch (e) {
			error = `Failed to load details: ${e.message}`;
			console.error('❌ Fetch error:', e);
		}
		loading = false;
	}

	async function handleSave() {
		if (!englishValue.trim()) {
			error = 'English value cannot be empty';
			return;
		}

		saving = true;
		error = null;
		success = null;

		try {
			const url = `${API_BASE}/Admin/Translations/UpdateEnglish`;
			console.log(`💾 Saving English translation to: ${url}`);
			const response = await fetch(url, {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({
					translationKey: currentKey,
					newEnglishValue: englishValue,
					strategy: updateStrategy
				})
			});

			const text = await response.text();
			let data;
			try {
				data = JSON.parse(text);
			} catch (parseErr) {
				console.error('JSON Parse Error:', parseErr.message);
				error = `Invalid response: ${parseErr.message}`;
				saving = false;
				return;
			}

			if (data.success) {
				success = `✓ Updated "${currentKey}" and ${data.affectedTranslations} language(s) marked for review`;
				oldEnglishValue = englishValue;
				console.log('✅ Translation saved successfully');
				dispatch('updated');

				// Clear success message after 5 seconds
				setTimeout(() => {
					success = null;
				}, 5000);
			} else {
				error = data.message;
			}
		} catch (e) {
			error = `Failed to save: ${e.message}`;
		}

		saving = false;
	}

	function handleCancel() {
		englishValue = oldEnglishValue;
		error = null;
	}

	function hasChanges() {
		return englishValue !== oldEnglishValue;
	}
</script>

<div class="english-editor">
	<div class="editor-header">
		<h2>English Translation</h2>
		<span class="key-badge">{translationKey}</span>
	</div>

	{#if loading}
		<div class="loading">Loading...</div>
	{:else}
		<div class="editor-content">
			<!-- Used in views section -->
			{#if usedInViews.length > 0}
				<div class="used-in-views">
					<h3>Used in {usedInViews.length} view{usedInViews.length !== 1 ? 's' : ''}</h3>
					<div class="views-list">
						{#each usedInViews as view}
							<span class="view-tag">
								<span class="view-type">{view.viewType}</span>
								<span class="view-name">{view.viewId}</span>
							</span>
						{/each}
					</div>
				</div>
			{/if}

			<!-- Error message -->
			{#if error}
				<div class="error-box">{error}</div>
			{/if}

			<!-- Success message -->
			{#if success}
				<div class="success-box">{success}</div>
			{/if}

			<!-- English value editor -->
			<div class="editor-section">
				<label for="english-input" class="label">English Value</label>
				<textarea
					id="english-input"
					bind:value={englishValue}
					placeholder="Enter English translation"
					disabled={loading}
					rows="4"
				/>
				<p class="char-count">{englishValue.length} characters</p>
			</div>

			<!-- Update strategy -->
			{#if hasChanges()}
				<div class="strategy-section">
					<label class="label">When English changes:</label>
					<div class="strategy-options">
						<label class="radio-option">
							<input
								type="radio"
								value="manual_review"
								bind:group={updateStrategy}
								disabled={saving}
							/>
							<span class="radio-label">
								<strong>Mark for Review</strong>
								<small>Clear other languages - translators must update them</small>
							</span>
						</label>

						<label class="radio-option">
							<input
								type="radio"
								value="clear_others"
								bind:group={updateStrategy}
								disabled={saving}
							/>
							<span class="radio-label">
								<strong>Clear All Translations</strong>
								<small>Empty all non-English translations</small>
							</span>
						</label>
					</div>
				</div>
			{/if}

			<!-- Action buttons -->
			<div class="button-group">
				{#if hasChanges()}
					<button class="btn btn-primary" on:click={handleSave} disabled={saving}>
						{saving ? '💾 Saving...' : '💾 Save Changes'}
					</button>
					<button class="btn btn-secondary" on:click={handleCancel} disabled={saving}>
						Cancel
					</button>
				{:else}
					<p class="no-changes">No changes to save</p>
				{/if}
			</div>
		</div>
	{/if}
</div>

<style>
	.english-editor {
		display: flex;
		flex-direction: column;
		height: 100%;
		background: white;
		overflow-y: auto;
	}

	.editor-header {
		padding: 20px;
		border-bottom: 2px solid #0066cc;
		flex-shrink: 0;
	}

	.editor-header h2 {
		margin: 0 0 10px 0;
		font-size: 18px;
		color: #333;
	}

	.key-badge {
		display: inline-block;
		background: #e8f4ff;
		color: #0066cc;
		padding: 6px 12px;
		border-radius: 4px;
		font-family: 'Monaco', 'Menlo', monospace;
		font-size: 12px;
		font-weight: bold;
	}

	.loading {
		padding: 40px 20px;
		text-align: center;
		color: #999;
	}

	.editor-content {
		padding: 20px;
		flex: 1;
	}

	.used-in-views {
		margin-bottom: 20px;
		padding: 15px;
		background: #f0f8ff;
		border-radius: 4px;
		border-left: 4px solid #0066cc;
	}

	.used-in-views h3 {
		margin: 0 0 10px 0;
		font-size: 14px;
		color: #0066cc;
	}

	.views-list {
		display: flex;
		flex-wrap: wrap;
		gap: 8px;
	}

	.view-tag {
		display: inline-flex;
		align-items: center;
		gap: 6px;
		padding: 6px 10px;
		background: white;
		border: 1px solid #0066cc;
		border-radius: 3px;
		font-size: 12px;
	}

	.view-type {
		background: #0066cc;
		color: white;
		padding: 2px 6px;
		border-radius: 2px;
		font-weight: bold;
		font-size: 10px;
	}

	.view-name {
		color: #333;
		font-weight: 500;
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

	.editor-section {
		margin-bottom: 20px;
	}

	.label {
		display: block;
		margin-bottom: 8px;
		font-weight: 600;
		font-size: 14px;
		color: #333;
	}

	textarea {
		width: 100%;
		padding: 12px;
		border: 1px solid #ddd;
		border-radius: 4px;
		font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
		font-size: 14px;
		line-height: 1.5;
		box-sizing: border-box;
		resize: vertical;
	}

	textarea:focus {
		outline: none;
		border-color: #0066cc;
		box-shadow: 0 0 0 3px rgba(0, 102, 204, 0.1);
	}

	textarea:disabled {
		background: #f9f9f9;
		color: #999;
		cursor: not-allowed;
	}

	.char-count {
		margin-top: 6px;
		font-size: 12px;
		color: #999;
	}

	.strategy-section {
		margin-bottom: 20px;
		padding: 15px;
		background: #fffef0;
		border-radius: 4px;
		border: 1px solid #f0e0a0;
	}

	.strategy-options {
		display: flex;
		flex-direction: column;
		gap: 12px;
	}

	.radio-option {
		display: flex;
		align-items: flex-start;
		gap: 10px;
		cursor: pointer;
	}

	.radio-option input[type='radio'] {
		margin-top: 4px;
		cursor: pointer;
	}

	.radio-label {
		display: flex;
		flex-direction: column;
		gap: 4px;
	}

	.radio-label strong {
		font-size: 14px;
		color: #333;
	}

	.radio-label small {
		font-size: 12px;
		color: #666;
		font-weight: normal;
	}

	.button-group {
		display: flex;
		gap: 10px;
		margin-top: 30px;
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
		transform: translateY(-1px);
		box-shadow: 0 4px 8px rgba(0, 102, 204, 0.3);
	}

	.btn-primary:disabled {
		opacity: 0.6;
		cursor: not-allowed;
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

	.no-changes {
		color: #999;
		font-size: 14px;
		margin: 0;
	}
</style>
