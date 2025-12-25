<script>
	import { createEventDispatcher } from 'svelte';

	export let views = [];
	export let selectedKey = null;

	const dispatch = createEventDispatcher();

	let searchQuery = '';
	let expandedViewId = null;

	$: filteredViews = views.filter((view) => {
		const query = searchQuery.toLowerCase();
		if (!query) return true;
		return (
			view.viewId.toLowerCase().includes(query) ||
			view.translationKeys.some((k) => k.toLowerCase().includes(query))
		);
	});

	function toggleView(viewId) {
		expandedViewId = expandedViewId === viewId ? null : viewId;
	}

	function selectKey(key) {
		dispatch('keySelected', key);
	}

	function selectView(view) {
		dispatch('viewSelected', view);
	}
</script>

<div class="view-list">
	<div class="search-box">
		<input
			type="text"
			placeholder="Search views or keys..."
			bind:value={searchQuery}
			class="search-input"
		/>
	</div>

	<div class="views-container">
		{#each filteredViews as view (view.viewId)}
			<div class="view-item">
				<button
					class="view-header"
					on:click={() => {
						toggleView(view.viewId);
						selectView(view);
					}}
					class:expanded={expandedViewId === view.viewId}
				>
					<span class="toggle-arrow">
						{expandedViewId === view.viewId ? '▼' : '▶'}
					</span>
					<span class="view-type-badge" class:ios={view.viewType === 'iOS'}>
						{view.viewType}
					</span>
					<span class="view-name">{view.viewId}</span>
					<span class="key-count">{view.keyCount}</span>
				</button>

				{#if expandedViewId === view.viewId}
					<div class="keys-list">
						{#each view.translationKeys as key}
							<button
								class="key-item"
								on:click={() => selectKey(key)}
								class:selected={selectedKey === key}
							>
								<span class="key-text">{key}</span>
							</button>
						{/each}
					</div>
				{/if}
			</div>
		{/each}
	</div>
</div>

<style>
	.view-list {
		display: flex;
		flex-direction: column;
		height: 100%;
		background: white;
	}

	.search-box {
		padding: 15px;
		border-bottom: 1px solid #e0e0e0;
		flex-shrink: 0;
	}

	.search-input {
		width: 100%;
		padding: 10px;
		border: 1px solid #ddd;
		border-radius: 4px;
		font-size: 14px;
		box-sizing: border-box;
	}

	.search-input:focus {
		outline: none;
		border-color: #0066cc;
		box-shadow: 0 0 0 3px rgba(0, 102, 204, 0.1);
	}

	.views-container {
		flex: 1;
		overflow-y: auto;
	}

	.view-item {
		border-bottom: 1px solid #f0f0f0;
	}

	.view-header {
		width: 100%;
		padding: 12px 15px;
		background: white;
		border: none;
		text-align: left;
		cursor: pointer;
		display: flex;
		align-items: center;
		gap: 10px;
		font-size: 14px;
		transition: background-color 0.15s;
	}

	.view-header:hover {
		background-color: #f9f9f9;
	}

	.view-header.expanded {
		background-color: #f0f5ff;
		border-bottom: 1px solid #ddd;
	}

	.toggle-arrow {
		display: inline-block;
		width: 16px;
		text-align: center;
		font-size: 12px;
		color: #999;
	}

	.view-type-badge {
		display: inline-block;
		padding: 3px 8px;
		background: #e8f4f8;
		color: #0066cc;
		border-radius: 3px;
		font-size: 11px;
		font-weight: bold;
		min-width: 35px;
		text-align: center;
	}

	.view-type-badge.ios {
		background: #f0e8f8;
		color: #6b3fb8;
	}

	.view-name {
		flex: 1;
		font-weight: 500;
		color: #333;
	}

	.key-count {
		background: #f0f0f0;
		padding: 2px 8px;
		border-radius: 3px;
		font-size: 12px;
		color: #666;
		font-weight: bold;
	}

	.keys-list {
		background: #fafafa;
		border-bottom: 1px solid #f0f0f0;
	}

	.key-item {
		width: 100%;
		padding: 10px 15px 10px 40px;
		background: none;
		border: none;
		text-align: left;
		cursor: pointer;
		font-size: 13px;
		color: #666;
		overflow: hidden;
		text-overflow: ellipsis;
		white-space: nowrap;
		transition: background-color 0.15s;
	}

	.key-item:hover {
		background-color: #f0f0f0;
	}

	.key-item.selected {
		background-color: #e8f4ff;
		color: #0066cc;
		font-weight: 500;
	}

	.key-text {
		font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
		font-size: 12px;
	}
</style>
