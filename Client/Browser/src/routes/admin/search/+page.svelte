<script>
	import AdminLayout from '../admin/AdminLayout.svelte';
	import SearchView from '../admin/SearchView.svelte';
	import { viewState } from '../../lib/adminStore.js';

	// Set to search view on page load
	viewState.set({ currentView: 'search', breadcrumbs: [] });
</script>

<AdminLayout>
	<SearchView />
</AdminLayout>
