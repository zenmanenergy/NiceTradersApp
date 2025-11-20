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
	
	function goToTerms() {
		goto('/terms');
	}
	
	// Scroll to top when page loads
	import { onMount } from 'svelte';
	onMount(() => {
		window.scrollTo(0, 0);
	});
</script>

<svelte:head>
	<title>Privacy Policy - NICE Traders</title>
	<meta name="description" content="Privacy Policy for NICE Traders currency exchange platform" />
</svelte:head>

<main class="privacy-container">
	<div class="header">
		<button class="back-button" on:click={goBack}>
			<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
				<polyline points="15,18 9,12 15,6"></polyline>
			</svg>
		</button>
		<h1 class="page-title">Privacy Policy</h1>
		<div class="spacer"></div>
	</div>

	<div class="content">
		<div class="intro-section">
			<h2 class="app-title">NICE Traders</h2>
			<p class="subtitle">Neighborhood International Currency Exchange</p>
			<p class="effective-date">Effective Date: November 15, 2025</p>
			<p class="last-updated">Last Updated: November 15, 2025</p>
		</div>

		<div class="privacy-content">
			<section class="privacy-section">
				<h3>1. Information We Collect</h3>
				<p>NICE Traders collects information to provide a safe and effective currency exchange platform. We collect the following types of information:</p>
				
				<h4>Personal Information You Provide:</h4>
				<ul>
					<li><strong>Account Information:</strong> Name, email address, phone number</li>
					<li><strong>Profile Information:</strong> Profile photo (optional), user preferences</li>
					<li><strong>Currency Listings:</strong> Currency type, amounts, location preferences</li>
					<li><strong>Communication Data:</strong> Messages sent through our platform</li>
					<li><strong>Payment Information:</strong> Payment method details for our $1 service fee</li>
				</ul>

				<h4>Information We Collect Automatically:</h4>
				<ul>
					<li><strong>Location Data:</strong> Approximate location for matching nearby users</li>
					<li><strong>Device Information:</strong> Device type, operating system, browser information</li>
					<li><strong>Usage Data:</strong> How you interact with our app, features used</li>
					<li><strong>Log Data:</strong> IP address, access times, pages viewed</li>
				</ul>
			</section>

			<section class="privacy-section">
				<h3>2. How We Use Your Information</h3>
				<p>We use the information we collect to:</p>
				<ul>
					<li><strong>Provide Our Service:</strong> Connect you with other users for currency exchange</li>
					<li><strong>Location Matching:</strong> Show you nearby currency exchange opportunities</li>
					<li><strong>Communication:</strong> Enable messaging between matched users</li>
					<li><strong>Safety & Security:</strong> Verify users, prevent fraud, and maintain platform safety</li>
					<li><strong>Payment Processing:</strong> Process our $1 service fee per transaction</li>
					<li><strong>Customer Support:</strong> Respond to your questions and provide assistance</li>
					<li><strong>Service Improvement:</strong> Analyze usage patterns to improve our platform</li>
					<li><strong>Legal Compliance:</strong> Comply with applicable laws and regulations</li>
				</ul>
			</section>

			<section class="privacy-section">
				<h3>3. Information Sharing and Disclosure</h3>
				<p>We respect your privacy and limit information sharing. We may share your information:</p>
				
				<h4>With Other Users:</h4>
				<ul>
					<li>Basic profile information (name, rating) when you connect for exchanges</li>
					<li>Messages you send through our platform</li>
					<li>Your general location area (not exact address)</li>
				</ul>

				<h4>With Service Providers:</h4>
				<ul>
					<li>Payment processors for handling service fees</li>
					<li>Cloud storage providers for data hosting</li>
					<li>Analytics services to improve our platform</li>
				</ul>

				<h4>For Legal Reasons:</h4>
				<ul>
					<li>When required by law or legal process</li>
					<li>To protect our rights, property, or safety</li>
					<li>To prevent fraud or illegal activity</li>
					<li>In connection with investigations by law enforcement</li>
				</ul>
			</section>

			<section class="privacy-section">
				<h3>4. Location Information</h3>
				<p>Location data is essential for NICE Traders functionality:</p>
				<ul>
					<li><strong>Purpose:</strong> To show you nearby currency exchange opportunities</li>
					<li><strong>Precision:</strong> We use approximate location (city/neighborhood level)</li>
					<li><strong>Control:</strong> You can disable location sharing in your device settings</li>
					<li><strong>Storage:</strong> Location data is stored securely and not shared with third parties</li>
				</ul>
				<div class="info-box">
					<p><strong>Note:</strong> Disabling location sharing may limit your ability to find nearby exchanges.</p>
				</div>
			</section>

			<section class="privacy-section">
				<h3>5. Data Security</h3>
				<p>We implement security measures to protect your information:</p>
				<ul>
					<li><strong>Encryption:</strong> Data is encrypted in transit and at rest</li>
					<li><strong>Access Controls:</strong> Limited employee access on a need-to-know basis</li>
					<li><strong>Regular Audits:</strong> Security practices are regularly reviewed and updated</li>
					<li><strong>Secure Infrastructure:</strong> We use industry-standard hosting and security services</li>
				</ul>
				<p>However, no method of transmission over the internet is 100% secure. We cannot guarantee absolute security of your information.</p>
			</section>

			<section class="privacy-section">
				<h3>6. Data Retention</h3>
				<p>We retain your information for different periods:</p>
				<ul>
					<li><strong>Account Data:</strong> Until you delete your account</li>
					<li><strong>Transaction Records:</strong> 7 years for legal and tax compliance</li>
					<li><strong>Messages:</strong> 90 days after exchange completion</li>
					<li><strong>Usage Logs:</strong> 12 months for security and analytics</li>
				</ul>
			</section>

			<section class="privacy-section">
				<h3>7. Your Privacy Rights</h3>
				<p>You have the following rights regarding your personal information:</p>
				<ul>
					<li><strong>Access:</strong> Request a copy of your personal information</li>
					<li><strong>Correction:</strong> Update or correct inaccurate information</li>
					<li><strong>Deletion:</strong> Request deletion of your account and data</li>
					<li><strong>Portability:</strong> Request your data in a portable format</li>
					<li><strong>Opt-out:</strong> Unsubscribe from marketing communications</li>
				</ul>
				<p>To exercise these rights, contact us at privacy@nicetraders.net</p>
			</section>

			<section class="privacy-section">
				<h3>8. Children's Privacy</h3>
				<p>NICE Traders is not intended for users under 18 years of age. We do not knowingly collect personal information from children under 18. If you are a parent or guardian and believe your child has provided us with personal information, please contact us.</p>
			</section>

			<section class="privacy-section">
				<h3>9. International Data Transfers</h3>
				<p>Your information may be transferred to and processed in countries other than your own. We ensure appropriate safeguards are in place to protect your information during international transfers.</p>
			</section>

			<section class="privacy-section">
				<h3>10. Changes to This Privacy Policy</h3>
				<p>We may update this Privacy Policy from time to time. We will notify you of any material changes by:</p>
				<ul>
					<li>Posting the new Privacy Policy on this page</li>
					<li>Sending you an email notification</li>
					<li>Providing an in-app notification</li>
				</ul>
				<p>Changes become effective 30 days after posting unless otherwise specified.</p>
			</section>

			<section class="privacy-section">
				<h3>11. Contact Us</h3>
				<p>If you have questions about this Privacy Policy or our privacy practices, contact us:</p>
				<div class="contact-info">
					<p><strong>Email:</strong> privacy@nicetraders.net</p>
					<p><strong>Support:</strong> support@nicetraders.net</p>
					<p><strong>Website:</strong> https://nicetraders.net</p>
					<p><strong>Mailing Address:</strong><br>
					NICE Traders Privacy Team<br>
					[Address to be added]</p>
				</div>
			</section>
		</div>

		<div class="cross-reference">
			<div class="reference-box">
				<p><strong>Related Documents:</strong></p>
				<p>Read our <button type="button" class="link-button" on:click={goToTerms}>Terms of Service</button> for more information about using NICE Traders.</p>
			</div>
		</div>
	</div>
</main>

<style>
	.privacy-container {
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
		margin: 0 0 0.25rem;
		font-style: italic;
	}

	.last-updated {
		font-size: 0.85rem;
		opacity: 0.8;
		margin: 0;
		font-style: italic;
	}

	.privacy-content {
		padding: 2rem 1.5rem 1rem;
	}

	.privacy-section {
		margin-bottom: 2rem;
	}

	.privacy-section h3 {
		color: #2d3748;
		font-size: 1.1rem;
		font-weight: 600;
		margin: 0 0 0.75rem;
		padding-bottom: 0.5rem;
		border-bottom: 2px solid #e2e8f0;
	}

	.privacy-section h4 {
		color: #4a5568;
		font-size: 1rem;
		font-weight: 600;
		margin: 1rem 0 0.5rem;
	}

	.privacy-section p {
		color: #4a5568;
		line-height: 1.6;
		margin: 0 0 1rem;
		font-size: 0.95rem;
	}

	.privacy-section ul {
		margin: 0 0 1rem;
		padding-left: 1.25rem;
	}

	.privacy-section li {
		color: #4a5568;
		line-height: 1.6;
		margin-bottom: 0.5rem;
		font-size: 0.95rem;
	}

	.info-box {
		background: #fff5f5;
		border: 1px solid #fed7d7;
		border-radius: 8px;
		padding: 1rem;
		margin: 1rem 0;
	}

	.info-box p {
		color: #744210;
		margin: 0;
		font-size: 0.9rem;
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

	.cross-reference {
		padding: 1rem 1.5rem 2rem;
	}

	.reference-box {
		background: #f0fff4;
		border: 2px solid #68d391;
		border-radius: 12px;
		padding: 1.5rem;
		text-align: center;
	}

	.reference-box p {
		color: #2d3748;
		font-size: 0.9rem;
		line-height: 1.5;
		margin: 0 0 0.5rem;
	}

	.reference-box p:last-child {
		margin-bottom: 0;
	}

	.link-button {
		background: none;
		border: none;
		color: #667eea;
		font-weight: 600;
		cursor: pointer;
		text-decoration: underline;
		font-size: 0.9rem;
	}

	.link-button:hover {
		color: #5a67d8;
	}

	/* Responsive adjustments */
	@media (max-width: 375px) {
		.privacy-container {
			max-width: 375px;
		}
		
		.intro-section {
			padding: 1.5rem 1rem;
		}
		
		.privacy-content {
			padding: 1.5rem 1rem 0.5rem;
		}
		
		.cross-reference {
			padding: 0.5rem 1rem 1.5rem;
		}
		
		.app-title {
			font-size: 1.8rem;
		}
	}

	@media (max-width: 320px) {
		.privacy-container {
			max-width: 320px;
		}
		
		.header {
			padding: 1rem;
		}
		
		.intro-section {
			padding: 1.25rem 0.75rem;
		}
		
		.privacy-content {
			padding: 1.25rem 0.75rem 0.5rem;
		}
		
		.app-title {
			font-size: 1.6rem;
		}
		
		.privacy-section h3 {
			font-size: 1rem;
		}
	}
</style>