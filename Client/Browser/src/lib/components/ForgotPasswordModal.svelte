<script>
	import { Settings } from '../../Settings.js';

	export let onClose = () => {};
	export let onBackToLogin = () => {};

	let step = 'email'; // 'email' or 'reset'
	let email = '';
	let resetToken = '';
	let newPassword = '';
	let confirmPassword = '';
	let errors = {};
	let successMessage = '';
	let isSubmitting = false;

	function validateEmail() {
		errors = {};
		if (!email.trim()) {
			errors.email = 'Email is required';
			return false;
		}
		if (!/\S+@\S+\.\S+/.test(email)) {
			errors.email = 'Please enter a valid email';
			return false;
		}
		return true;
	}

	function validateResetPassword() {
		errors = {};
		if (!resetToken.trim()) {
			errors.resetToken = 'Reset code is required';
			return false;
		}
		if (!newPassword) {
			errors.newPassword = 'Password is required';
			return false;
		}
		if (newPassword.length < 6) {
			errors.newPassword = 'Password must be at least 6 characters';
			return false;
		}
		if (newPassword !== confirmPassword) {
			errors.confirmPassword = 'Passwords do not match';
			return false;
		}
		return true;
	}

	async function handleEmailSubmit() {
		if (!validateEmail()) return;

		isSubmitting = true;
		successMessage = '';
		errors = {};

		try {
			const response = await fetch(`${Settings.baseURL}/Login/ForgotPassword`, {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json'
				},
				body: JSON.stringify({ email })
			});

			const result = await response.json();

			if (result.success) {
				successMessage = result.message || 'Check your email for reset instructions';
				// Show reset code input after successful request
				step = 'reset';
				// In production, the reset token would be sent via email
				// For development, we can use the returned token
				if (result.resetToken) {
					resetToken = result.resetToken;
				}
			} else {
				errors.general = result.error || 'Failed to process request';
			}
		} catch (error) {
			errors.general = 'Error connecting to server: ' + error.message;
		} finally {
			isSubmitting = false;
		}
	}

	async function handleResetPasswordSubmit() {
		if (!validateResetPassword()) return;

		isSubmitting = true;

		try {
			const response = await fetch(`${Settings.baseURL}/Login/ResetPassword`, {
				method: 'POST',
				headers: {
					'Content-Type': 'application/json'
				},
				body: JSON.stringify({
					resetToken,
					newPassword
				})
			});

			const result = await response.json();

			if (result.success) {
				successMessage = 'Password reset successful! Redirecting to login...';
				setTimeout(() => {
					onBackToLogin();
				}, 2000);
			} else {
				errors.general = result.error || 'Failed to reset password';
			}
		} catch (error) {
			errors.general = 'Error connecting to server: ' + error.message;
		} finally {
			isSubmitting = false;
		}
	}
</script>

<div class="forgot-password-modal">
	<div class="modal-content">
		<button class="close-button" on:click={onClose}>×</button>

		{#if step === 'email'}
			<h2>Reset Your Password</h2>
			<p class="subtitle">Enter your email address and we'll send you a reset code</p>

			{#if errors.general}
				<div class="error-message">{errors.general}</div>
			{/if}

			<form on:submit|preventDefault={handleEmailSubmit}>
				<div class="form-group">
					<label for="reset-email">Email Address</label>
					<input
						type="email"
						id="reset-email"
						bind:value={email}
						placeholder="Enter your email"
						class:error={errors.email}
						disabled={isSubmitting}
					/>
					{#if errors.email}
						<span class="error-text">{errors.email}</span>
					{/if}
				</div>

				<button type="submit" class="submit-button" disabled={isSubmitting}>
					{#if isSubmitting}
						Sending...
					{:else}
						Send Reset Code
					{/if}
				</button>
			</form>

			<button class="back-button" on:click={onBackToLogin}>Back to Login</button>
		{:else if step === 'reset'}
			<h2>Reset Your Password</h2>

			{#if successMessage}
				<div class="success-message">{successMessage}</div>
			{/if}

			{#if errors.general}
				<div class="error-message">{errors.general}</div>
			{/if}

			<form on:submit|preventDefault={handleResetPasswordSubmit}>
				<div class="form-group">
					<label for="reset-token">Reset Code</label>
					<input
						type="text"
						id="reset-token"
						bind:value={resetToken}
						placeholder="Enter the code from your email"
						class:error={errors.resetToken}
						disabled={isSubmitting}
					/>
					{#if errors.resetToken}
						<span class="error-text">{errors.resetToken}</span>
					{/if}
				</div>

				<div class="form-group">
					<label for="new-password">New Password</label>
					<input
						type="password"
						id="new-password"
						bind:value={newPassword}
						placeholder="Enter new password (min 6 characters)"
						class:error={errors.newPassword}
						disabled={isSubmitting}
					/>
					{#if errors.newPassword}
						<span class="error-text">{errors.newPassword}</span>
					{/if}
				</div>

				<div class="form-group">
					<label for="confirm-password">Confirm Password</label>
					<input
						type="password"
						id="confirm-password"
						bind:value={confirmPassword}
						placeholder="Confirm your password"
						class:error={errors.confirmPassword}
						disabled={isSubmitting}
					/>
					{#if errors.confirmPassword}
						<span class="error-text">{errors.confirmPassword}</span>
					{/if}
				</div>

				<button type="submit" class="submit-button" disabled={isSubmitting}>
					{#if isSubmitting}
						Resetting...
					{:else}
						Reset Password
					{/if}
				</button>
			</form>

			<button class="back-button" on:click={() => { step = 'email'; errors = {}; }}>
				Back
			</button>
		{/if}
	</div>
</div>

<style>
	.forgot-password-modal {
		position: fixed;
		top: 0;
		left: 0;
		right: 0;
		bottom: 0;
		background: rgba(0, 0, 0, 0.5);
		display: flex;
		align-items: center;
		justify-content: center;
		z-index: 1000;
	}

	.modal-content {
		background: white;
		border-radius: 12px;
		padding: 2rem;
		max-width: 400px;
		width: 90%;
		box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
		position: relative;
	}

	.close-button {
		position: absolute;
		top: 1rem;
		right: 1rem;
		background: none;
		border: none;
		font-size: 1.5rem;
		cursor: pointer;
		color: #666;
		padding: 0;
		width: 24px;
		height: 24px;
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.close-button:hover {
		color: #000;
	}

	h2 {
		font-size: 1.5rem;
		font-weight: 600;
		margin-bottom: 0.5rem;
		color: #333;
	}

	.subtitle {
		color: #666;
		font-size: 0.875rem;
		margin-bottom: 1.5rem;
	}

	.form-group {
		margin-bottom: 1.5rem;
	}

	label {
		display: block;
		font-weight: 500;
		margin-bottom: 0.5rem;
		color: #333;
		font-size: 0.875rem;
	}

	input {
		width: 100%;
		padding: 0.75rem;
		border: 2px solid #e0e0e0;
		border-radius: 8px;
		font-size: 1rem;
		transition: border-color 0.2s;
		box-sizing: border-box;
	}

	input:focus {
		outline: none;
		border-color: #667eea;
	}

	input.error {
		border-color: #ef4444;
	}

	input:disabled {
		background: #f5f5f5;
		cursor: not-allowed;
	}

	.error-text {
		display: block;
		color: #ef4444;
		font-size: 0.75rem;
		margin-top: 0.25rem;
	}

	.error-message {
		background: #fee;
		color: #c33;
		padding: 0.75rem;
		border-radius: 8px;
		margin-bottom: 1rem;
		font-size: 0.875rem;
		border-left: 4px solid #c33;
	}

	.success-message {
		background: #efe;
		color: #3c3;
		padding: 0.75rem;
		border-radius: 8px;
		margin-bottom: 1rem;
		font-size: 0.875rem;
		border-left: 4px solid #3c3;
	}

	.submit-button {
		width: 100%;
		padding: 0.75rem;
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		color: white;
		border: none;
		border-radius: 8px;
		font-size: 1rem;
		font-weight: 600;
		cursor: pointer;
		transition: opacity 0.2s;
	}

	.submit-button:hover:not(:disabled) {
		opacity: 0.9;
	}

	.submit-button:disabled {
		opacity: 0.6;
		cursor: not-allowed;
	}

	.back-button {
		width: 100%;
		padding: 0.75rem;
		background: none;
		color: #667eea;
		border: 2px solid #667eea;
		border-radius: 8px;
		font-size: 1rem;
		font-weight: 600;
		cursor: pointer;
		margin-top: 1rem;
		transition: background-color 0.2s;
	}

	.back-button:hover {
		background: rgba(102, 126, 234, 0.1);
	}
</style>
