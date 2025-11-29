<script>
	import { goto } from '$app/navigation';
	import { handleLogin } from './handleLogin.js';
	import ForgotPasswordModal from '$lib/components/ForgotPasswordModal.svelte';
	
	let formData = {
		email: '',
		password: ''
	};
	
	let errors = {};
	let isSubmitting = false;
	let showForgotPassword = false;
	
	function validateForm() {
		errors = {};
		
		if (!formData.email.trim()) {
			errors.email = 'Email is required';
		} else if (!/\S+@\S+\.\S+/.test(formData.email)) {
			errors.email = 'Please enter a valid email';
		}
		
		if (!formData.password) {
			errors.password = 'Password is required';
		}
		
		return Object.keys(errors).length === 0;
	}
	
	async function handleSubmit() {
		if (!validateForm()) return;
		
		isSubmitting = true;
		
		// Call the handleLogin function
		await handleLogin(
			formData.email,
			formData.password,
			validateForm(),
			(success) => {
				isSubmitting = false;
				if (success) {
					// Success handling is done in handleLogin (redirect to dashboard)
					console.log('Login successful');
				} else {
					// Error handling is done in handleLogin (shows error message)
					console.log('Login failed');
				}
			}
		);
	}
	
	function goBack() {
		goto('/');
	}
	
	function goToSignup() {
		goto('/signup');
	}
	
	function handleForgotPassword() {
		showForgotPassword = true;
	}
	
	function closeForgotPassword() {
		showForgotPassword = false;
	}
</script>

{#if showForgotPassword}
	<ForgotPasswordModal onClose={closeForgotPassword} onBackToLogin={closeForgotPassword} />
{/if}

<main class="login-container">
	<div class="header">
		<button class="back-button" on:click={goBack}>
			<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
				<polyline points="15,18 9,12 15,6"></polyline>
			</svg>
		</button>
		<h1 class="page-title">Sign In</h1>
		<div class="spacer"></div>
	</div>

	<div class="content">
		<div class="welcome-text">
			<h2 class="welcome-title">Welcome Back</h2>
		</div>

		<form on:submit|preventDefault={handleSubmit} class="login-form">
			<div class="form-group">
				<label for="email" class="form-label">Email Address</label>
				<input 
					type="email" 
					id="email"
					bind:value={formData.email}
					class="form-input"
					class:error={errors.email}
					placeholder="Enter your email"
					autocomplete="email"
				/>
				{#if errors.email}
					<span class="error-message">{errors.email}</span>
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
					placeholder="Enter your password"
					autocomplete="current-password"
				/>
				{#if errors.password}
					<span class="error-message">{errors.password}</span>
				{/if}
			</div>

			<div class="form-options">
				<button 
					type="button" 
					class="forgot-link"
					on:click={handleForgotPassword}
				>
					Forgot Password?
				</button>
			</div>

			<button 
				type="submit" 
				class="submit-button"
				disabled={isSubmitting}
			>
				{#if isSubmitting}
					<span class="loading-spinner"></span>
					Signing In...
				{:else}
					Sign In
				{/if}
			</button>
		</form>

		<div class="divider">
			<span class="divider-text">or</span>
		</div>

		<div class="social-login">
			<button class="social-button">
				<svg width="20" height="20" viewBox="0 0 24 24">
					<path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
					<path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
					<path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
					<path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
				</svg>
				Continue with Google
			</button>
		</div>

		<div class="signup-link">
			<p>Don't have an account? <button type="button" class="link-button" on:click={goToSignup}>Sign Up</button></p>
		</div>
	</div>
</main>

<style>
	.login-container {
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
		margin-bottom: 2.5rem;
	}

	.app-logo {
		font-size: 3rem;
		margin-bottom: 1rem;
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

	.login-form {
		margin-bottom: 2rem;
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

	.form-options {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 2rem;
	}



	.forgot-link {
		background: none;
		border: none;
		color: #667eea;
		font-size: 0.9rem;
		cursor: pointer;
		text-decoration: none;
		font-weight: 500;
	}

	.forgot-link:hover {
		text-decoration: underline;
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

	.divider {
		text-align: center;
		margin: 2rem 0;
		position: relative;
	}

	.divider::before {
		content: '';
		position: absolute;
		top: 50%;
		left: 0;
		right: 0;
		height: 1px;
		background: #e2e8f0;
	}

	.divider-text {
		background: white;
		padding: 0 1rem;
		color: #a0aec0;
		font-size: 0.9rem;
	}

	.social-login {
		display: flex;
		flex-direction: column;
		gap: 1rem;
		margin-bottom: 2rem;
	}

	.social-button {
		width: 100%;
		padding: 0.875rem 1rem;
		border: 2px solid #e2e8f0;
		border-radius: 12px;
		background: white;
		color: #2d3748;
		font-size: 1rem;
		font-weight: 500;
		cursor: pointer;
		transition: all 0.2s ease;
		display: flex;
		align-items: center;
		justify-content: center;
		gap: 0.75rem;
	}

	.social-button:hover {
		border-color: #cbd5e0;
		background: #f7fafc;
	}

	.signup-link {
		text-align: center;
	}

	.signup-link p {
		margin: 0;
		color: #718096;
		font-size: 0.95rem;
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

	@media (max-width: 375px) {
		.login-container {
			max-width: 375px;
		}
		
		.content {
			padding: 1.5rem 1rem;
		}
		
		.form-options {
			flex-direction: column;
			gap: 1rem;
			align-items: flex-start;
		}
	}

	@media (max-width: 320px) {
		.login-container {
			max-width: 320px;
		}
		
		.header {
			padding: 1rem;
		}
		
		.welcome-title {
			font-size: 1.6rem;
		}
		
		.app-logo {
			font-size: 2.5rem;
		}
	}
</style>