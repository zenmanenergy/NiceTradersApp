<script>
	import favicon from '$lib/assets/favicon.svg';
	import AdminHeader from '$lib/AdminHeader.svelte';
	import { page } from '$app/stores';

	let { children } = $props();
	
	// Show header on all pages except login
	$: showHeader = $page.url.pathname !== '/login';
</script>

<svelte:head>
	<link rel="icon" href={favicon} />
</svelte:head>

{#if showHeader}
	<AdminHeader />
{/if}

{@render children()}
