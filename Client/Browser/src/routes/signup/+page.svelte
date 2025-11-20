<script>
	import { goto } from '$app/navigation';
	import { handleSignup, checkEmailExists } from './handleSignup.js';
	
	let formData = {
		firstName: '',
		lastName: '',
		email: '',
		phone: '',
		password: '',
		confirmPassword: ''
	};
	
	let errors = {};
	let isSubmitting = false;
	
	function validateForm() {
		errors = {};
		
		if (!formData.firstName.trim()) {
			errors.firstName = 'First name is required';
		}
		
		if (!formData.lastName.trim()) {
			errors.lastName = 'Last name is required';
		}
		
		if (!formData.email.trim()) {
			errors.email = 'Email is required';
		} else if (!/\S+@\S+\.\S+/.test(formData.email)) {
			errors.email = 'Please enter a valid email';
		}
		
		if (!formData.phone.trim()) {
			errors.phone = 'Phone number is required';
		}
		
		if (!formData.password) {
			errors.password = 'Password is required';
		} else if (formData.password.length < 6) {
			errors.password = 'Password must be at least 6 characters';
		}
		
		if (formData.password !== formData.confirmPassword) {
			errors.confirmPassword = 'Passwords do not match';
		}
		
		return Object.keys(errors).length === 0;
	}
	
	async function handleSubmit() {
		if (!validateForm()) return;
		
		isSubmitting = true;
		
		// Call the handleSignup function
		await handleSignup(
			formData.firstName,
			formData.lastName,
			formData.email,
			formData.phone,
			formData.password,
			validateForm(),
			(success) => {
				isSubmitting = false;
				if (success) {
					// Success handling is done in handleSignup (redirect to dashboard)
					console.log('Account created successfully');
				} else {
					// Error handling is done in handleSignup (shows error message)
					console.log('Account creation failed');
				}
			}
		);
	}
	
	function goBack() {
		goto('/');
	}
</script>

<main class="signup-container">
	<div class="header">
		<button class="back-button" on:click={goBack}>
			<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
				<polyline points="15,18 9,12 15,6"></polyline>
			</svg>
		</button>
		<h1 class="page-title">Create Account</h1>
		<div class="spacer"></div>
	</div>

	<div class="content">
		<div class="welcome-text">
			<h2 class="welcome-title">Join NICE Traders</h2>
			<p class="welcome-subtitle">Start exchanging currency with your neighbors</p>
		</div>

		<form on:submit|preventDefault={handleSubmit} class="signup-form">
			<div class="form-row">
				<div class="form-group">
					<label for="firstName" class="form-label">First Name</label>
					<input 
						type="text" 
						id="firstName"
						bind:value={formData.firstName}
						class="form-input"
						class:error={errors.firstName}
						placeholder="Enter your first name"
					/>
					{#if errors.firstName}
						<span class="error-message">{errors.firstName}</span>
					{/if}
				</div>

				<div class="form-group">
					<label for="lastName" class="form-label">Last Name</label>
					<input 
						type="text" 
						id="lastName"
						bind:value={formData.lastName}
						class="form-input"
						class:error={errors.lastName}
						placeholder="Enter your last name"
					/>
					{#if errors.lastName}
						<span class="error-message">{errors.lastName}</span>
					{/if}
				</div>
			</div>

			<div class="form-group">
				<label for="email" class="form-label">Email Address</label>
				<input 
					type="email" 
					id="email"
					bind:value={formData.email}
					class="form-input"
					class:error={errors.email}
					placeholder="Enter your email"
				/>
				{#if errors.email}
					<span class="error-message">{errors.email}</span>
				{/if}
			</div>

			<div class="form-group">
				<label for="phone" class="form-label">Phone Number</label>
				<input 
					type="tel" 
					id="phone"
					bind:value={formData.phone}
					class="form-input"
					class:error={errors.phone}
					placeholder="Enter your phone number"
				/>
				{#if errors.phone}
					<span class="error-message">{errors.phone}</span>
				{/if}
			</div>

			<div class="form-group">
				<label for="password" class="form-label">Password</label>
				<input 
					type="password" 
					id="password"
					bind:value={formData.password}
					class="form-input"
					class:error={errors.password}
					placeholder="Create a password"
				/>
				{#if errors.password}
					<span class="error-message">{errors.password}</span>
				{/if}
			</div>

			<div class="form-group">
				<label for="confirmPassword" class="form-label">Confirm Password</label>
				<input 
					type="password" 
					id="confirmPassword"
					bind:value={formData.confirmPassword}
					class="form-input"
					class:error={errors.confirmPassword}
					placeholder="Confirm your password"
				/>
				{#if errors.confirmPassword}
					<span class="error-message">{errors.confirmPassword}</span>
				{/if}
			</div>

			<button 
				type="submit" 
				class="submit-button"
				disabled={isSubmitting}
			>
				{#if isSubmitting}
					<span class="loading-spinner"></span>
					Creating Account...
				{:else}
					Create Account
				{/if}
			</button>
		</form>

		<div class="login-link">
			<p>Already have an account? <button type="button" class="link-button" on:click={() => goto('/login')}>Sign In</button></p>
		</div>

		<div class="terms">
			<p class="terms-text">
				By creating an account, you agree to our 
				<a href="/terms" class="link">Terms of Service</a> and 
				<a href="/privacy" class="link">Privacy Policy</a>
			</p>
		</div>
	</div>
</main>

<style>
	.signup-container {
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
		padding: 2rem 1.5rem;
		overflow-y: auto;
	}

	.welcome-text {
		text-align: center;
		margin-bottom: 2rem;
	}

	.welcome-title {
		font-size: 1.8rem;
		font-weight: 600;
		color: #2d3748;
		margin: 0 0 0.5rem;
	}

	.welcome-subtitle {
		font-size: 1rem;
		color: #718096;
		margin: 0;
	}

	.signup-form {
		margin-bottom: 2rem;
	}

	.form-row {
		display: flex;
		gap: 1rem;
		margin-bottom: 1rem;
	}

	.form-row .form-group {
		flex: 1;
	}

	.form-group {
		margin-bottom: 1.5rem;
	}

	.form-label {
		display: block;
		font-size: 0.9rem;
		font-weight: 500;
		color: #2d3748;
		margin-bottom: 0.5rem;
	}

	.form-input {
		width: 100%;
		padding: 0.875rem 1rem;
		border: 2px solid #e2e8f0;
		border-radius: 12px;
		font-size: 1rem;
		transition: border-color 0.2s, box-shadow 0.2s;
		background: white;
		box-sizing: border-box;
	}

	.form-input:focus {
		outline: none;
		border-color: #667eea;
		box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
	}

	.form-input.error {
		border-color: #e53e3e;
	}

	.form-input::placeholder {
		color: #a0aec0;
	}

	.error-message {
		display: block;
		font-size: 0.8rem;
		color: #e53e3e;
		margin-top: 0.25rem;
	}

	.submit-button {
		width: 100%;
		padding: 1rem;
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		color: white;
		border: none;
		border-radius: 12px;
		font-size: 1.1rem;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.3s ease;
		display: flex;
		align-items: center;
		justify-content: center;
		gap: 0.5rem;
		margin-top: 1rem;
	}

	.submit-button:hover:not(:disabled) {
		transform: translateY(-2px);
		box-shadow: 0 8px 25px rgba(102, 126, 234, 0.4);
	}

	.submit-button:disabled {
		opacity: 0.7;
		cursor: not-allowed;
		transform: none;
	}

	.loading-spinner {
		width: 20px;
		height: 20px;
		border: 2px solid rgba(255, 255, 255, 0.3);
		border-top: 2px solid white;
		border-radius: 50%;
		animation: spin 1s linear infinite;
	}

	@keyframes spin {
		from { transform: rotate(0deg); }
		to { transform: rotate(360deg); }
	}

	.login-link {
		text-align: center;
		margin-bottom: 1.5rem;
	}

	.login-link p {
		margin: 0;
		color: #718096;
		font-size: 0.95rem;
	}

	.link {
		color: #667eea;
		text-decoration: none;
		font-weight: 500;
	}

	.link:hover {
		text-decoration: underline;
	}

	.link-button {
		background: none;
		border: none;
		color: #667eea;
		font-weight: 500;
		cursor: pointer;
		text-decoration: none;
		font-size: 0.95rem;
	}

	.link-button:hover {
		text-decoration: underline;
	}

	.terms {
		text-align: center;
	}

	.terms-text {
		font-size: 0.8rem;
		color: #a0aec0;
		line-height: 1.5;
		margin: 0;
	}

	@media (max-width: 375px) {
		.signup-container {
			max-width: 375px;
		}
		
		.content {
			padding: 1.5rem 1rem;
		}
		
		.form-row {
			flex-direction: column;
			gap: 0;
		}
		
		.form-row .form-group {
			margin-bottom: 1.5rem;
		}
	}

	@media (max-width: 320px) {
		.signup-container {
			max-width: 320px;
		}
		
		.header {
			padding: 1rem;
		}
		
		.welcome-title {
			font-size: 1.6rem;
		}
	}
</style>