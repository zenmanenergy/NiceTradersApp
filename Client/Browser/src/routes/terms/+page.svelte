<script>
	import { goto } from '$app/navigation';
	
	function goBack() {
		// Go back to previous page or signup if accessed directly
		if (window.history.length > 1) {
			window.history.back();
		} else {
			goto('/signup');
		}
	}
	
	// Scroll to top when page loads
	import { onMount } from 'svelte';
	onMount(() => {
		window.scrollTo(0, 0);
	});
</script>

<svelte:head>
	<title>Terms of Service - NICE Traders</title>
	<meta name="description" content="Terms of Service for NICE Traders currency exchange platform" />
</svelte:head>

<main class="terms-container">
	<div class="header">
		<button class="back-button" on:click={goBack}>
			<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
				<polyline points="15,18 9,12 15,6"></polyline>
			</svg>
		</button>
		<h1 class="page-title">Terms of Service</h1>
		<div class="spacer"></div>
	</div>

	<div class="content">
		<div class="intro-section">
			<h2 class="app-title">NICE Traders</h2>
			<p class="subtitle">Neighborhood International Currency Exchange</p>
			<p class="effective-date">Effective Date: November 15, 2025</p>
		</div>

		<div class="terms-content">
			<section class="terms-section">
				<h3>1. Acceptance of Terms</h3>
				<p>By accessing and using NICE Traders ("the Service"), you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.</p>
			</section>

			<section class="terms-section">
				<h3>2. Description of Service</h3>
				<p>NICE Traders is a peer-to-peer platform that connects individuals who want to exchange foreign currency in person within their local communities. The Service:</p>
				<ul>
					<li>Allows users to list foreign currency they wish to exchange</li>
					<li>Enables users to search for available currency exchanges nearby</li>
					<li>Facilitates communication between users through our messaging system</li>
					<li>Provides a rating system for user safety and trust</li>
					<li>Charges a $1 fee per person for each exchange transaction</li>
				</ul>
			</section>

			<section class="terms-section">
				<h3>3. User Responsibilities</h3>
				<p>As a user of NICE Traders, you agree to:</p>
				<ul>
					<li>Provide accurate and truthful information when creating listings</li>
					<li>Meet other users only in safe, public locations</li>
					<li>Conduct exchanges honestly and fairly</li>
					<li>Respect other users and maintain professional conduct</li>
					<li>Comply with all applicable local and international laws regarding currency exchange</li>
					<li>Not use the Service for money laundering or other illegal activities</li>
				</ul>
			</section>

			<section class="terms-section">
				<h3>4. Safety and Security</h3>
				<p>Your safety is important to us. NICE Traders:</p>
				<ul>
					<li>Recommends meeting only in well-lit, public places</li>
					<li>Provides suggested safe meeting locations</li>
					<li>Offers user rating and review systems</li>
					<li>Reserves the right to suspend accounts for suspicious activity</li>
				</ul>
				<p><strong>Important:</strong> NICE Traders is not responsible for the safety of in-person meetings. Users assume all risks associated with meeting other users.</p>
			</section>

			<section class="terms-section">
				<h3>5. Fees and Payments</h3>
				<p>NICE Traders charges a $1 fee per person for each currency exchange transaction. This fee:</p>
				<ul>
					<li>Is charged when users unlock messaging to communicate</li>
					<li>Helps maintain platform security and prevent spam</li>
					<li>Is non-refundable once messaging is unlocked</li>
					<li>Does not guarantee completion of currency exchange</li>
				</ul>
			</section>

			<section class="terms-section">
				<h3>6. Privacy Policy</h3>
				<p>Your privacy is important to us. Our Privacy Policy explains how we collect, use, and protect your information when you use our Service. By using NICE Traders, you agree to the collection and use of information in accordance with our Privacy Policy.</p>
			</section>

			<section class="terms-section">
				<h3>7. Prohibited Uses</h3>
				<p>You may not use NICE Traders for:</p>
				<ul>
					<li>Any unlawful purpose or to solicit others to perform unlawful acts</li>
					<li>Money laundering or other financial crimes</li>
					<li>Harassment, abuse, or harm of another person</li>
					<li>Creating false or misleading listings</li>
					<li>Impersonating another person or entity</li>
					<li>Attempting to circumvent our fee structure</li>
				</ul>
			</section>

			<section class="terms-section">
				<h3>8. Limitation of Liability</h3>
				<p>NICE Traders provides a platform for users to connect but does not:</p>
				<ul>
					<li>Guarantee the completion of any currency exchange</li>
					<li>Verify the authenticity of currency being exchanged</li>
					<li>Take responsibility for disputes between users</li>
					<li>Assume liability for losses incurred during exchanges</li>
				</ul>
				<p>Users engage in currency exchanges at their own risk.</p>
			</section>

			<section class="terms-section">
				<h3>9. Account Termination</h3>
				<p>We reserve the right to terminate or suspend your account immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach the Terms.</p>
			</section>

			<section class="terms-section">
				<h3>10. Changes to Terms</h3>
				<p>We reserve the right, at our sole discretion, to modify or replace these Terms at any time. If revisions are material, we will try to provide at least 30 days notice prior to any new terms taking effect.</p>
			</section>

			<section class="terms-section">
				<h3>11. Contact Information</h3>
				<p>If you have any questions about these Terms of Service, please contact us at:</p>
				<div class="contact-info">
					<p><strong>Email:</strong> support@nicetraders.net</p>
					<p><strong>Website:</strong> https://nicetraders.net</p>
				</div>
			</section>
		</div>

		<div class="acceptance-section">
			<div class="acceptance-box">
				<p><strong>By creating an account with NICE Traders, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.</strong></p>
			</div>
		</div>
	</div>
</main>

<style>
	.terms-container {
		max-width: 414px;
		margin: 0 auto;
		min-height: 100vh;
		background: white;
		display: flex;
		flex-direction: column;
		box-shadow: 0 0 20px rgba(0, 0, 0, 0.1);
	}

	.header {
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		color: white;
		padding: 1rem 1.5rem;
		display: flex;
		align-items: center;
		justify-content: space-between;
		min-height: 60px;
		position: sticky;
		top: 0;
		z-index: 10;
		box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
	}

	.back-button {
		background: none;
		border: none;
		color: white;
		cursor: pointer;
		padding: 0.5rem;
		border-radius: 8px;
		transition: background-color 0.2s;
	}

	.back-button:hover {
		background: rgba(255, 255, 255, 0.1);
	}

	.page-title {
		font-size: 1.25rem;
		font-weight: 600;
		margin: 0;
	}

	.spacer {
		width: 40px;
	}

	.content {
		flex: 1;
		padding: 0;
		overflow-y: auto;
	}

	.intro-section {
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		color: white;
		text-align: center;
		padding: 2rem 1.5rem;
		margin-bottom: 0;
	}

	.app-title {
		font-size: 2rem;
		font-weight: 700;
		margin: 0 0 0.5rem;
	}

	.subtitle {
		font-size: 0.9rem;
		opacity: 0.9;
		margin: 0 0 1rem;
	}

	.effective-date {
		font-size: 0.85rem;
		opacity: 0.8;
		margin: 0;
		font-style: italic;
	}

	.terms-content {
		padding: 2rem 1.5rem 1rem;
	}

	.terms-section {
		margin-bottom: 2rem;
	}

	.terms-section h3 {
		color: #2d3748;
		font-size: 1.1rem;
		font-weight: 600;
		margin: 0 0 0.75rem;
		padding-bottom: 0.5rem;
		border-bottom: 2px solid #e2e8f0;
	}

	.terms-section p {
		color: #4a5568;
		line-height: 1.6;
		margin: 0 0 1rem;
		font-size: 0.95rem;
	}

	.terms-section ul {
		margin: 0 0 1rem;
		padding-left: 1.25rem;
	}

	.terms-section li {
		color: #4a5568;
		line-height: 1.6;
		margin-bottom: 0.5rem;
		font-size: 0.95rem;
	}

	.contact-info {
		background: #f7fafc;
		padding: 1rem;
		border-radius: 8px;
		margin-top: 0.5rem;
	}

	.contact-info p {
		margin: 0 0 0.5rem;
		font-size: 0.9rem;
	}

	.contact-info p:last-child {
		margin-bottom: 0;
	}

	.acceptance-section {
		padding: 1rem 1.5rem 2rem;
	}

	.acceptance-box {
		background: #e6fffa;
		border: 2px solid #38b2ac;
		border-radius: 12px;
		padding: 1.5rem;
		text-align: center;
	}

	.acceptance-box p {
		color: #2d3748;
		font-size: 0.9rem;
		line-height: 1.5;
		margin: 0;
	}

	/* Responsive adjustments */
	@media (max-width: 375px) {
		.terms-container {
			max-width: 375px;
		}
		
		.intro-section {
			padding: 1.5rem 1rem;
		}
		
		.terms-content {
			padding: 1.5rem 1rem 0.5rem;
		}
		
		.acceptance-section {
			padding: 0.5rem 1rem 1.5rem;
		}
		
		.app-title {
			font-size: 1.8rem;
		}
	}

	@media (max-width: 320px) {
		.terms-container {
			max-width: 320px;
		}
		
		.header {
			padding: 1rem;
		}
		
		.intro-section {
			padding: 1.25rem 0.75rem;
		}
		
		.terms-content {
			padding: 1.25rem 0.75rem 0.5rem;
		}
		
		.app-title {
			font-size: 1.6rem;
		}
		
		.terms-section h3 {
			font-size: 1rem;
		}
	}
</style>