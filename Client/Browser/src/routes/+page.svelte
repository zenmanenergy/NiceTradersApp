<script>
	import { goto } from '$app/navigation';
	
	function handleGetStarted() {
		goto('/signup');
	}
	
	function handleLearnMore() {
		// For now, just scroll to features or show more info
		alert('Learn More coming soon! This is just a prototype.');
	}
</script>

<main class="welcome-container">
	<div class="header">
		<div class="logo">
			<h1 class="app-title">NICE Traders</h1>
			<p class="app-subtitle">Neighborhood International Currency Exchange</p>
		</div>
	</div>

	<div class="hero-section">
		<div class="hero-icon">💱</div>
		<h2 class="hero-title">Exchange Currency Locally</h2>
		<p class="hero-description">
			Connect with neighbors to exchange foreign currency safely and affordably. 
			Skip the expensive fees and get the cash you need from your community.
		</p>
	</div>

	<div class="features-section">
		<div class="feature">
			<div class="feature-icon">🗺️</div>
			<div class="feature-text">
				<h3>Find Nearby</h3>
				<p>See currency exchanges happening in your neighborhood</p>
			</div>
		</div>
		
		<div class="feature">
			<div class="feature-icon">💰</div>
			<div class="feature-text">
				<h3>Better Rates</h3>
				<p>Avoid high bank and airport exchange fees</p>
			</div>
		</div>
		
		<div class="feature">
			<div class="feature-icon">🛡️</div>
			<div class="feature-text">
				<h3>Safe Exchanges</h3>
				<p>Meet in public places with user ratings for safety</p>
			</div>
		</div>
	</div>

	<div class="cta-section">
		<button class="cta-button primary" on:click={handleGetStarted}>Get Started</button>
		<button class="cta-button secondary" on:click={handleLearnMore}>Learn More</button>
	</div>

	<div class="footer">
		<p class="footer-text">Join thousands of travelers saving money on currency exchange</p>
	</div>
</main>

<style>
	/* Mobile-first responsive design */
	:global(body) {
		margin: 0;
		padding: 0;
		font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		min-height: 100vh;
		color: #333;
	}

	.welcome-container {
		max-width: 414px; /* iPhone Pro Max width */
		margin: 0 auto;
		min-height: 100vh;
		background: white;
		display: flex;
		flex-direction: column;
		padding: 0;
		box-shadow: 0 0 20px rgba(0, 0, 0, 0.1);
	}

	/* Header Section */
	.header {
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		color: white;
		text-align: center;
		padding: 2rem 1.5rem 3rem;
		border-radius: 0 0 30px 30px;
	}

	.app-title {
		font-size: 2.5rem;
		font-weight: 700;
		margin: 0;
		letter-spacing: -0.5px;
	}

	.app-subtitle {
		font-size: 0.9rem;
		margin: 0.5rem 0 0;
		opacity: 0.9;
		font-weight: 300;
	}

	/* Hero Section */
	.hero-section {
		text-align: center;
		padding: 2rem 1.5rem;
		flex-grow: 1;
	}

	.hero-icon {
		font-size: 4rem;
		margin-bottom: 1rem;
	}

	.hero-title {
		font-size: 1.8rem;
		font-weight: 600;
		margin: 0 0 1rem;
		color: #2d3748;
	}

	.hero-description {
		font-size: 1rem;
		line-height: 1.6;
		color: #718096;
		margin: 0 0 2rem;
	}

	/* Features Section */
	.features-section {
		padding: 0 1.5rem 2rem;
	}

	.feature {
		display: flex;
		align-items: center;
		margin-bottom: 1.5rem;
		padding: 1rem;
		background: #f7fafc;
		border-radius: 12px;
		border-left: 4px solid #667eea;
	}

	.feature-icon {
		font-size: 2rem;
		margin-right: 1rem;
		min-width: 3rem;
		text-align: center;
	}

	.feature-text h3 {
		font-size: 1.1rem;
		font-weight: 600;
		margin: 0 0 0.25rem;
		color: #2d3748;
	}

	.feature-text p {
		font-size: 0.9rem;
		color: #718096;
		margin: 0;
		line-height: 1.4;
	}

	/* CTA Section */
	.cta-section {
		padding: 2rem 1.5rem;
		display: flex;
		flex-direction: column;
		gap: 1rem;
	}

	.cta-button {
		width: 100%;
		padding: 1rem;
		border-radius: 12px;
		font-size: 1.1rem;
		font-weight: 600;
		border: none;
		cursor: pointer;
		transition: all 0.3s ease;
	}

	.cta-button.primary {
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		color: white;
		box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
	}

	.cta-button.primary:hover {
		transform: translateY(-2px);
		box-shadow: 0 8px 25px rgba(102, 126, 234, 0.5);
	}

	.cta-button.secondary {
		background: transparent;
		color: #667eea;
		border: 2px solid #667eea;
	}

	.cta-button.secondary:hover {
		background: #667eea;
		color: white;
	}

	/* Footer */
	.footer {
		padding: 1.5rem;
		text-align: center;
		background: #f7fafc;
		margin-top: auto;
	}

	.footer-text {
		font-size: 0.85rem;
		color: #718096;
		margin: 0;
	}

	/* Responsive adjustments */
	@media (max-width: 375px) {
		.welcome-container {
			max-width: 375px;
		}
		
		.app-title {
			font-size: 2.2rem;
		}
		
		.hero-title {
			font-size: 1.6rem;
		}
		
		.feature {
			padding: 0.75rem;
		}
	}

	@media (max-width: 320px) {
		.welcome-container {
			max-width: 320px;
		}
		
		.header {
			padding: 1.5rem 1rem 2.5rem;
		}
		
		.app-title {
			font-size: 2rem;
		}
		
		.hero-section {
			padding: 1.5rem 1rem;
		}
		
		.cta-section {
			padding: 1.5rem 1rem;
		}
	}
</style>
