<script>
	import { page } from '$app/stores';
</script>

<!-- Top Navigation Menu -->
<nav class="top-menu">
	<div class="menu-container">
		<div class="logo">
			<a href="/">🏪 Nice Traders Admin</a>
		</div>
		<ul class="menu-links">
			<li><a href="/" class:active={$page.url.pathname === '/'}>Dashboard</a></li>
			<li><a href="/search" class:active={$page.url.pathname === '/search'}>Search</a></li>
			<li><a href="/terminal" class:active={$page.url.pathname === '/terminal'}>Terminal</a></li>
			<li><a href="/localization" class:active={$page.url.pathname === '/localization'}>Localization</a></li>
			<li><a href="/payment-reports" class:active={$page.url.pathname === '/payment-reports'}>Reports</a></li>
			<li><a href="/exchange-rates" class:active={$page.url.pathname === '/exchange-rates'}>Exchange Rates</a></li>
		</ul>
		<div class="menu-actions">
			<a href="/profile" class="user-link">👤 Profile</a>
			<a href="/login" class="logout-link">🚪 Logout</a>
		</div>
	</div>
</nav>

<style>
	/* Top Navigation Menu */
	.top-menu {
		background: #1a1a1a;
		border-bottom: 3px solid #0066cc;
		padding: 0;
		box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
		position: sticky;
		top: 0;
		z-index: 1000;
	}

	.menu-container {
		max-width: 1400px;
		margin: 0 auto;
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 0 20px;
		height: 60px;
	}

	.logo a {
		color: white;
		text-decoration: none;
		font-size: 16px;
		font-weight: 700;
		letter-spacing: 0.5px;
		transition: color 0.2s;
		white-space: nowrap;
	}

	.logo a:hover {
		color: #0066cc;
	}

	.menu-links {
		display: flex;
		list-style: none;
		gap: 0;
		margin: 0;
		padding: 0;
		flex: 1;
		justify-content: center;
	}

	.menu-links li {
		margin: 0;
		padding: 0;
	}

	.menu-links a {
		display: block;
		color: #ccc;
		text-decoration: none;
		padding: 20px 18px;
		font-size: 14px;
		font-weight: 500;
		transition: all 0.2s;
		border-bottom: 3px solid transparent;
		height: 100%;
		line-height: 20px;
	}

	.menu-links a:hover {
		color: white;
		background: rgba(0, 102, 204, 0.1);
		border-bottom-color: #0066cc;
	}

	.menu-links a.active {
		color: #0066cc;
		border-bottom-color: #0066cc;
		background: rgba(0, 102, 204, 0.05);
	}

	.menu-actions {
		display: flex;
		gap: 15px;
		align-items: center;
		white-space: nowrap;
	}

	.user-link,
	.logout-link {
		color: #ccc;
		text-decoration: none;
		font-size: 13px;
		padding: 6px 12px;
		border-radius: 4px;
		transition: all 0.2s;
	}

	.user-link:hover {
		color: white;
		background: rgba(0, 102, 204, 0.2);
	}

	.logout-link:hover {
		color: #ff6b6b;
		background: rgba(255, 107, 107, 0.1);
	}

	@media (max-width: 1000px) {
		.menu-links {
			gap: 5px;
		}

		.menu-links a {
			padding: 20px 12px;
			font-size: 12px;
		}

		.logo a {
			font-size: 14px;
		}

		.menu-actions {
			gap: 10px;
		}

		.user-link,
		.logout-link {
			font-size: 11px;
			padding: 4px 8px;
		}
	}

	@media (max-width: 700px) {
		.menu-links {
			display: none;
		}

		.menu-container {
			justify-content: space-between;
		}
	}
</style>
