<script>
	import { goto } from '$app/navigation';
	import { onMount } from 'svelte';
	import { Session } from '../../Session.js';
	import { handleCreateListing } from './handleListings.js';
	
	// Popular currencies with flag images and full names
	const currencies = [
		{ code: 'USD', name: 'US Dollar', popular: true },
		{ code: 'EUR', name: 'Euro', popular: true },
		{ code: 'GBP', name: 'British Pound', popular: true },
		{ code: 'JPY', name: 'Japanese Yen', popular: true },
		{ code: 'CAD', name: 'Canadian Dollar', popular: true },
		{ code: 'AUD', name: 'Australian Dollar', popular: true },
		{ code: 'CHF', name: 'Swiss Franc', popular: true },
		{ code: 'CNY', name: 'Chinese Yuan', popular: false },
		{ code: 'SEK', name: 'Swedish Krona', popular: false },
		{ code: 'NOK', name: 'Norwegian Krone', popular: false },
		{ code: 'DKK', name: 'Danish Krone', popular: false },
		{ code: 'PLN', name: 'Polish Złoty', popular: false },
		{ code: 'CZK', name: 'Czech Koruna', popular: false },
		{ code: 'HUF', name: 'Hungarian Forint', popular: false },
		{ code: 'RUB', name: 'Russian Ruble', popular: false },
		{ code: 'KRW', name: 'South Korean Won', popular: false },
		{ code: 'SGD', name: 'Singapore Dollar', popular: false },
		{ code: 'HKD', name: 'Hong Kong Dollar', popular: false },
		{ code: 'NZD', name: 'New Zealand Dollar', popular: false },
		{ code: 'MXN', name: 'Mexican Peso', popular: false },
		{ code: 'BRL', name: 'Brazilian Real', popular: false },
		{ code: 'INR', name: 'Indian Rupee', popular: false },
		{ code: 'ZAR', name: 'South African Rand', popular: false },
		{ code: 'TRY', name: 'Turkish Lira', popular: false },
		{ code: 'THB', name: 'Thai Baht', popular: false },
		{ code: 'IDR', name: 'Indonesian Rupiah', popular: false },
		{ code: 'MYR', name: 'Malaysian Ringgit', popular: false },
		{ code: 'PHP', name: 'Philippine Peso', popular: false },
		{ code: 'AED', name: 'UAE Dirham', popular: false },
		{ code: 'SAR', name: 'Saudi Riyal', popular: false },
		{ code: 'ILS', name: 'Israeli Shekel', popular: false },
		{ code: 'ARS', name: 'Argentine Peso', popular: false },
		{ code: 'CLP', name: 'Chilean Peso', popular: false },
		{ code: 'COP', name: 'Colombian Peso', popular: false },
		{ code: 'PEN', name: 'Peruvian Sol', popular: false },
		{ code: 'EGP', name: 'Egyptian Pound', popular: false },
		{ code: 'NGN', name: 'Nigerian Naira', popular: false },
		{ code: 'KES', name: 'Kenyan Shilling', popular: false },
		{ code: 'RON', name: 'Romanian Leu', popular: false },
		{ code: 'BGN', name: 'Bulgarian Lev', popular: false },
		{ code: 'HRK', name: 'Croatian Kuna', popular: false },
		{ code: 'ISK', name: 'Icelandic Króna', popular: false },
		{ code: 'UAH', name: 'Ukrainian Hryvnia', popular: false },
		{ code: 'VND', name: 'Vietnamese Dong', popular: false },
		{ code: 'PKR', name: 'Pakistani Rupee', popular: false },
		{ code: 'BDT', name: 'Bangladeshi Taka', popular: false },
		{ code: 'LKR', name: 'Sri Lankan Rupee', popular: false },
		{ code: 'QAR', name: 'Qatari Riyal', popular: false },
		{ code: 'KWD', name: 'Kuwaiti Dinar', popular: false },
		{ code: 'BHD', name: 'Bahraini Dinar', popular: false },
		{ code: 'OMR', name: 'Omani Rial', popular: false },
		{ code: 'JOD', name: 'Jordanian Dinar', popular: false },
		{ code: 'MAD', name: 'Moroccan Dirham', popular: false },
		{ code: 'TND', name: 'Tunisian Dinar', popular: false },
		{ code: 'DZD', name: 'Algerian Dinar', popular: false },
		{ code: 'GHS', name: 'Ghanaian Cedi', popular: false },
		{ code: 'UGX', name: 'Ugandan Shilling', popular: false },
		{ code: 'TZS', name: 'Tanzanian Shilling', popular: false },
		{ code: 'ETB', name: 'Ethiopian Birr', popular: false },
		{ code: 'ZMW', name: 'Zambian Kwacha', popular: false },
		{ code: 'MWK', name: 'Malawian Kwacha', popular: false },
		{ code: 'MUR', name: 'Mauritian Rupee', popular: false },
		{ code: 'SCR', name: 'Seychellois Rupee', popular: false },
		{ code: 'BWP', name: 'Botswana Pula', popular: false },
		{ code: 'NAD', name: 'Namibian Dollar', popular: false },
		{ code: 'SZL', name: 'Swazi Lilangeni', popular: false },
		{ code: 'LSL', name: 'Lesotho Loti', popular: false },
		{ code: 'AOA', name: 'Angolan Kwanza', popular: false },
		{ code: 'MZN', name: 'Mozambican Metical', popular: false },
		{ code: 'RWF', name: 'Rwandan Franc', popular: false },
		{ code: 'BIF', name: 'Burundian Franc', popular: false },
		{ code: 'CDF', name: 'Congolese Franc', popular: false },
		{ code: 'XAF', name: 'Central African CFA Franc', popular: false },
		{ code: 'XOF', name: 'West African CFA Franc', popular: false },
		{ code: 'KZT', name: 'Kazakhstani Tenge', popular: false },
		{ code: 'UZS', name: 'Uzbekistani Som', popular: false },
		{ code: 'AZN', name: 'Azerbaijani Manat', popular: false },
		{ code: 'GEL', name: 'Georgian Lari', popular: false },
		{ code: 'AMD', name: 'Armenian Dram', popular: false },
		{ code: 'KGS', name: 'Kyrgyzstani Som', popular: false },
		{ code: 'TJS', name: 'Tajikistani Somoni', popular: false },
		{ code: 'TMT', name: 'Turkmenistani Manat', popular: false },
		{ code: 'AFN', name: 'Afghan Afghani', popular: false },
		{ code: 'IRR', name: 'Iranian Rial', popular: false },
		{ code: 'IQD', name: 'Iraqi Dinar', popular: false },
		{ code: 'SYP', name: 'Syrian Pound', popular: false },
		{ code: 'LBP', name: 'Lebanese Pound', popular: false },
		{ code: 'YER', name: 'Yemeni Rial', popular: false },
		{ code: 'NPR', name: 'Nepalese Rupee', popular: false },
		{ code: 'BTN', name: 'Bhutanese Ngultrum', popular: false },
		{ code: 'MVR', name: 'Maldivian Rufiyaa', popular: false },
		{ code: 'MMK', name: 'Myanmar Kyat', popular: false },
		{ code: 'LAK', name: 'Lao Kip', popular: false },
		{ code: 'KHR', name: 'Cambodian Riel', popular: false },
		{ code: 'BND', name: 'Brunei Dollar', popular: false },
		{ code: 'TWD', name: 'New Taiwan Dollar', popular: false },
		{ code: 'MOP', name: 'Macanese Pataca', popular: false },
		{ code: 'MNT', name: 'Mongolian Tögrög', popular: false },
		{ code: 'KPW', name: 'North Korean Won', popular: false },
		{ code: 'FJD', name: 'Fijian Dollar', popular: false },
		{ code: 'PGK', name: 'Papua New Guinean Kina', popular: false },
		{ code: 'SBD', name: 'Solomon Islands Dollar', popular: false },
		{ code: 'VUV', name: 'Vanuatu Vatu', popular: false },
		{ code: 'WST', name: 'Samoan Tālā', popular: false },
		{ code: 'TOP', name: 'Tongan Paʻanga', popular: false },
		{ code: 'BYN', name: 'Belarusian Ruble', popular: false },
		{ code: 'MDL', name: 'Moldovan Leu', popular: false },
		{ code: 'RSD', name: 'Serbian Dinar', popular: false },
		{ code: 'MKD', name: 'Macedonian Denar', popular: false },
		{ code: 'ALL', name: 'Albanian Lek', popular: false },
		{ code: 'BAM', name: 'Bosnia-Herzegovina Mark', popular: false },
		{ code: 'CUP', name: 'Cuban Peso', popular: false },
		{ code: 'DOP', name: 'Dominican Peso', popular: false },
		{ code: 'GTQ', name: 'Guatemalan Quetzal', popular: false },
		{ code: 'HNL', name: 'Honduran Lempira', popular: false },
		{ code: 'NIO', name: 'Nicaraguan Córdoba', popular: false },
		{ code: 'PAB', name: 'Panamanian Balboa', popular: false },
		{ code: 'CRC', name: 'Costa Rican Colón', popular: false },
		{ code: 'JMD', name: 'Jamaican Dollar', popular: false },
		{ code: 'TTD', name: 'Trinidad & Tobago Dollar', popular: false },
		{ code: 'BBD', name: 'Barbadian Dollar', popular: false },
		{ code: 'BZD', name: 'Belize Dollar', popular: false },
		{ code: 'BSD', name: 'Bahamian Dollar', popular: false },
		{ code: 'HTG', name: 'Haitian Gourde', popular: false },
		{ code: 'XCD', name: 'East Caribbean Dollar', popular: false },
		{ code: 'AWG', name: 'Aruban Florin', popular: false },
		{ code: 'ANG', name: 'Netherlands Antillean Guilder', popular: false },
		{ code: 'SRD', name: 'Surinamese Dollar', popular: false },
		{ code: 'GYD', name: 'Guyanese Dollar', popular: false },
		{ code: 'PYG', name: 'Paraguayan Guaraní', popular: false },
		{ code: 'UYU', name: 'Uruguayan Peso', popular: false },
		{ code: 'BOB', name: 'Bolivian Boliviano', popular: false },
		{ code: 'VES', name: 'Venezuelan Bolívar', popular: false }
	];
	
	// Helper function to get flag image source
	function getFlagImage(currencyCode) {
		return `/images/flags/${currencyCode.toLowerCase()}.png`;
	}
	
	// Form data
	let formData = {
		currency: '',
		amount: '',
		acceptCurrency: '',
		location: '',
		locationRadius: '5', // Distance in miles
		meetingPreference: 'public',
		availableUntil: ''
	};
	
	let errors = {};
	let isSubmitting = false;
	let showAllCurrencies = false;
	let showAllAcceptCurrencies = false;
	let searchQuery = '';
	let searchQueryAccept = '';
	let currentStep = 1;
	const totalSteps = 3;
	
	// Filtered currencies based on search and popularity
	$: filteredCurrencies = currencies.filter(currency => {
		const matchesSearch = currency.code.toLowerCase().includes(searchQuery.toLowerCase()) || 
		                     currency.name.toLowerCase().includes(searchQuery.toLowerCase());
		const showPopular = !showAllCurrencies ? currency.popular : true;
		return matchesSearch && showPopular;
	});

	// Filtered accept currencies (excluding the selected "have" currency)
	$: filteredAcceptCurrencies = currencies.filter(currency => {
		const matchesSearch = currency.code.toLowerCase().includes(searchQueryAccept.toLowerCase()) || 
		                     currency.name.toLowerCase().includes(searchQueryAccept.toLowerCase());
		const showPopular = !showAllAcceptCurrencies ? currency.popular : true;
		const notSameCurrency = currency.code !== formData.currency;
		return matchesSearch && showPopular && notSameCurrency;
	});
	
	function goBack() {
		if (currentStep > 1) {
			currentStep--;
		} else {
			goto('/dashboard');
		}
	}
	
	function nextStep() {
		if (validateCurrentStep()) {
			currentStep++;
		}
	}
	
	function prevStep() {
		currentStep--;
	}
	
	function validateCurrentStep() {
		errors = {};
		
		if (currentStep === 1) {
			if (!formData.currency) {
				errors.currency = 'Please select a currency';
				return false;
			}
			if (!formData.amount || formData.amount <= 0) {
				errors.amount = 'Please enter a valid amount';
				return false;
			}
			if (!formData.acceptCurrency) {
				errors.acceptCurrency = 'Please select what currency you will accept';
				return false;
			}
		} else if (currentStep === 2) {
			if (locationStatus !== 'detected') {
				errors.location = 'Please detect your location first';
				return false;
			}
			if (!formData.availableUntil) {
				errors.availableUntil = 'Please select when this listing expires';
				return false;
			}
		}
		
		return true;
	}
	
	function selectCurrency(currency) {
		formData.currency = currency.code;
		searchQuery = '';
		// Reset accept currency if it's the same as the selected currency
		if (formData.acceptCurrency === currency.code) {
			formData.acceptCurrency = '';
		}
	}

	function selectAcceptCurrency(currencyCode) {
		formData.acceptCurrency = currencyCode;
		searchQueryAccept = '';
	}

	function getCurrencyName(code) {
		const currency = currencies.find(c => c.code === code);
		return currency ? currency.name : code;
	}

	// Mock exchange rate calculation (in real app, would call API)
	function calculateReceiveAmount() {
		if (!formData.amount || !formData.currency || !formData.acceptCurrency) return '0';
		
		// Mock exchange rates (USD base)
		const rates = {
			'USD': 1.0,
			'EUR': 0.85,
			'GBP': 0.73,
			'JPY': 110.0,
			'CAD': 1.25,
			'AUD': 1.35,
			'CHF': 0.92,
			'CNY': 6.45,
			'SEK': 8.5,
			'NZD': 1.4
		};
		
		const fromRate = rates[formData.currency] || 1.0;
		const toRate = rates[formData.acceptCurrency] || 1.0;
		const usdAmount = parseFloat(formData.amount) / fromRate;
		const targetAmount = usdAmount * toRate;
		
		// Round to nearest integer (no coins)
		return Math.round(targetAmount).toString();
	}
	
	async function handleSubmit() {
		if (!validateCurrentStep()) return;
		
		isSubmitting = true;
		errors = {}; // Clear any previous errors
		
		// Get session ID from cookies
		const sessionId = window.Cookies?.get('SessionId');
		if (!sessionId) {
			isSubmitting = false;
			errors.general = 'You must be logged in to create a listing';
			return;
		}
		
		// Prepare listing data
		const listingData = {
			currency: formData.currency,
			amount: formData.amount,
			acceptCurrency: formData.acceptCurrency,
			location: formData.location,
			locationRadius: formData.locationRadius,
			meetingPreference: formData.meetingPreference,
			availableUntil: formData.availableUntil
		};
		
		// Call API to create listing
		handleCreateListing(sessionId, listingData, (result) => {
			isSubmitting = false;
			
			if (result && result.success) {
				console.log('Listing created successfully:', result.listingId);
				// Show success message and redirect
				goto('/dashboard');
			} else {
				console.error('Failed to create listing:', result?.error);
				errors.general = result?.error || 'Failed to create listing. Please try again.';
			}
		});
	}
	
	function handleUseLocation() {
		locationStatus = 'detecting';
		
		if (navigator.geolocation) {
			navigator.geolocation.getCurrentPosition(
				(position) => {
					// In a real app, you'd reverse geocode these coordinates
					const lat = position.coords.latitude.toFixed(4);
					const lon = position.coords.longitude.toFixed(4);
					formData.location = `${lat}, ${lon}`;
					locationStatus = 'detected';
				},
				(error) => {
					console.error('Geolocation error:', error);
					// Fallback to mock location
					formData.location = 'San Francisco, CA (mock)';
					locationStatus = 'detected';
				}
			);
		} else {
			// Fallback for browsers without geolocation
			setTimeout(() => {
				formData.location = 'San Francisco, CA (mock)';
				locationStatus = 'detected';
			}, 1000);
		}
	}

	let locationStatus = 'unset'; // 'unset', 'detecting', 'detected'
	
	// Set default expiration date (7 days from now)
	onMount(async () => {
		await Session.handleSession();
		Session.GetSessionId(); // This sets Session.SessionId
		const sessionId = Session.SessionId;
		
		if (!sessionId) {
			goto('/login');
			return;
		}
		
		const weekFromNow = new Date();
		weekFromNow.setDate(weekFromNow.getDate() + 7);
		formData.availableUntil = weekFromNow.toISOString().split('T')[0];
	});
</script>

<svelte:head>
	<title>Create Listing - NICE Traders</title>
	<meta name="description" content="List your foreign currency for exchange" />
</svelte:head>

<main class="create-listing-container">
	<div class="header">
		<button class="back-button" on:click={goBack}>
			<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
				<polyline points="15,18 9,12 15,6"></polyline>
			</svg>
		</button>
		<h1 class="page-title">Create Listing</h1>
		<div class="spacer"></div>
	</div>

	<!-- Progress indicator -->
	<div class="progress-container">
		<div class="progress-bar">
			<div class="progress-fill" style="width: {(currentStep / totalSteps) * 100}%"></div>
		</div>
		<div class="progress-text">Step {currentStep} of {totalSteps}</div>
	</div>

	<div class="content">
		<!-- General Error Display -->
		{#if errors.general}
			<div class="error-banner">
				<div class="error-icon">⚠️</div>
				<div class="error-message">{errors.general}</div>
			</div>
		{/if}
		
		{#if currentStep === 1}
			<!-- Step 1: Currency and Amount -->
			<div class="step-content">
				<div class="step-header">
					<h2 class="step-title">What currency do you have?</h2>
					<p class="step-subtitle">Select the currency you want to exchange</p>
				</div>

				<!-- Currency Selection -->
				<div class="form-group">
					<label class="form-label">Currency You Have</label>
					
					{#if !formData.currency}
						<div class="currency-search">
							<input 
								type="text" 
								bind:value={searchQuery}
								placeholder="Search currencies..."
								class="search-input"
							/>
							<div class="search-icon">🔍</div>
						</div>

						<div class="currency-grid">
							{#each filteredCurrencies as currency}
								<button 
									class="currency-option"
									on:click={() => selectCurrency(currency)}
								>
									<div class="currency-flag">
										<img src={getFlagImage(currency.code)} alt="{currency.code} flag" class="flag-image" />
									</div>
									<div class="currency-info">
										<div class="currency-code">{currency.code}</div>
										<div class="currency-name">{currency.name}</div>
									</div>
								</button>
							{/each}
						</div>

						{#if !showAllCurrencies}
							<button 
								class="show-more-button"
								on:click={() => showAllCurrencies = true}
							>
								Show More Currencies
							</button>
						{/if}
					{:else}
						<div class="selected-currency">
							<div class="selected-currency-display">
								<img src={getFlagImage(formData.currency)} alt="{formData.currency} flag" class="selected-flag-image" />
								<span class="selected-code">{formData.currency}</span>
								<span class="selected-name">{currencies.find(c => c.code === formData.currency)?.name}</span>
							</div>
							<button 
								class="change-currency-button"
								on:click={() => formData.currency = ''}
							>
								Change
							</button>
						</div>
					{/if}
					
					{#if errors.currency}
						<span class="error-message">{errors.currency}</span>
					{/if}
				</div>

				<!-- Amount -->
				<div class="form-group">
					<label for="amount" class="form-label">Amount You Have</label>
					<div class="amount-input-container">
						<input 
							type="number" 
							id="amount"
							bind:value={formData.amount}
							class="form-input amount-input"
							class:error={errors.amount}
							placeholder="0"
							min="1"
							step="1"
						/>
						<span class="currency-suffix">{formData.currency || 'Currency'}</span>
					</div>
					{#if errors.amount}
						<span class="error-message">{errors.amount}</span>
					{/if}
					<div class="form-help">How much of this currency do you have available?</div>
				</div>

				<!-- Accept Currency -->
				<div class="form-group">
					<label class="form-label">What currency will you accept?</label>
					
					{#if !formData.acceptCurrency}
						<!-- Search -->
						<div class="search-container">
							<input 
								type="text" 
								bind:value={searchQueryAccept}
								class="search-input"
								placeholder="Search currencies..."
								on:input={() => {}}
							/>
						</div>

						<!-- Currency options -->
						<div class="currency-grid">
							{#each filteredAcceptCurrencies as currency}
								<button 
									class="currency-option"
									on:click={() => selectAcceptCurrency(currency.code)}
								>
									<img src={getFlagImage(currency.code)} alt="{currency.code} flag" class="flag-image" />
									<div class="currency-info">
										<span class="currency-code">{currency.code}</span>
										<span class="currency-name">{currency.name}</span>
									</div>
								</button>
							{/each}
						</div>

						{#if !showAllAcceptCurrencies}
							<button class="show-more-btn" on:click={() => showAllAcceptCurrencies = true}>
								Show all currencies
							</button>
						{/if}
					{:else}
						<!-- Selected currency -->
						<div class="selected-currency">
							<img src={getFlagImage(formData.acceptCurrency)} alt="{formData.acceptCurrency} flag" class="selected-flag" />
							<span class="selected-code">{formData.acceptCurrency}</span>
							<span class="selected-name">{getCurrencyName(formData.acceptCurrency)}</span>
							<button class="change-btn" on:click={() => formData.acceptCurrency = ''}>Change</button>
						</div>

						{#if formData.acceptCurrency && formData.amount}
							<div class="exchange-preview">
								<div class="exchange-calculation">
									<span class="from-amount">{formData.amount} {formData.currency}</span>
									<span class="arrow">→</span>
									<span class="to-amount">{calculateReceiveAmount()} {formData.acceptCurrency}</span>
								</div>
								<div class="exchange-note">Amount you'll receive (at market rate)</div>
							</div>
						{/if}
					{/if}
					<div class="form-help">Select the currency you're willing to accept in exchange</div>
				</div>
			</div>

		{:else if currentStep === 2}
			<!-- Step 2: Location and Preferences -->
			<div class="step-content">
				<div class="step-header">
					<h2 class="step-title">Where can you meet?</h2>
					<p class="step-subtitle">Help others find you for the exchange</p>
				</div>

				<!-- Location -->
				<div class="form-group">
					<label class="form-label">Your Location</label>
					
					{#if locationStatus === 'unset'}
						<div class="location-detector">
							<div class="location-prompt">
								<div class="location-icon">📍</div>
								<div class="location-text">
									<h3>Use your current location</h3>
									<p>We'll detect your location to help others find you nearby</p>
								</div>
							</div>
							<button 
								class="location-detect-btn"
								on:click={handleUseLocation}
								type="button"
							>
								Detect My Location
							</button>
						</div>
					{:else if locationStatus === 'detecting'}
						<div class="location-detecting">
							<div class="spinner"></div>
							<span>Detecting your location...</span>
						</div>
					{:else}
						<div class="location-detected">
							<div class="location-confirmed">
								<span class="location-icon">✅</span>
								<span class="location-text">Location detected</span>
								<button class="location-change-btn" on:click={() => locationStatus = 'unset'}>Change</button>
							</div>
						</div>
					{/if}
					
					{#if errors.location}
						<span class="error-message">{errors.location}</span>
					{/if}
					<div class="form-help">Your exact location stays private - others see general area only</div>
				</div>

				<!-- Distance Radius -->
				{#if locationStatus === 'detected'}
					<div class="form-group">
						<label for="radius" class="form-label">Meeting Distance</label>
						<select 
							id="radius"
							bind:value={formData.locationRadius}
							class="form-select"
						>
							<option value="1">Within 1 mile</option>
							<option value="3">Within 3 miles</option>
							<option value="5">Within 5 miles</option>
							<option value="10">Within 10 miles</option>
							<option value="25">Within 25 miles</option>
						</select>
						<div class="form-help">How far are you willing to travel to meet?</div>
					</div>
				{/if}

				<!-- Meeting Preference -->
				<div class="form-group">
					<label class="form-label">Meeting Preference</label>
					<div class="meeting-options">
						<label class="radio-option">
							<input 
								type="radio" 
								bind:group={formData.meetingPreference} 
								value="public"
								class="radio-input"
							/>
							<span class="radio-text">Public places only (Recommended)</span>
						</label>
						<label class="radio-option">
							<input 
								type="radio" 
								bind:group={formData.meetingPreference} 
								value="flexible"
								class="radio-input"
							/>
							<span class="radio-text">Flexible meeting locations</span>
						</label>
					</div>
				</div>

				<!-- Available Until -->
				<div class="form-group">
					<label for="availableUntil" class="form-label">Available Until</label>
					<input 
						type="date" 
						id="availableUntil"
						bind:value={formData.availableUntil}
						class="form-input"
						class:error={errors.availableUntil}
						min={new Date().toISOString().split('T')[0]}
					/>
					{#if errors.availableUntil}
						<span class="error-message">{errors.availableUntil}</span>
					{/if}
				</div>
			</div>

		{:else if currentStep === 3}
			<!-- Step 3: Review and Submit -->
			<div class="step-content">
				<div class="step-header">
					<h2 class="step-title">Review your listing</h2>
					<p class="step-subtitle">Make sure everything looks correct</p>
				</div>

				<div class="listing-preview">
					<div class="preview-header">
						<div class="preview-currency">
							<img src={getFlagImage(formData.currency)} alt="{formData.currency} flag" class="preview-flag-image" />
							<span class="preview-amount">{formData.amount} {formData.currency}</span>
						</div>
						<div class="preview-rate">
							{#if formData.exchangeRate === 'market'}
								Market Rate
							{:else}
								${formData.customRate} per {formData.currency}
							{/if}
						</div>
					</div>

					<div class="preview-details">
						<div class="preview-item">
							<span class="preview-label">Location:</span>
							<span class="preview-value">{formData.location}</span>
						</div>
						<div class="preview-item">
							<span class="preview-label">Meeting:</span>
							<span class="preview-value">
								{formData.meetingPreference === 'public' ? 'Public places only' : 'Flexible locations'}
							</span>
						</div>
						<div class="preview-item">
							<span class="preview-label">Available until:</span>
							<span class="preview-value">{new Date(formData.availableUntil).toLocaleDateString()}</span>
						</div>
					</div>


				</div>


			</div>
		{/if}
	</div>

	<!-- Footer Actions -->
	<div class="footer-actions">
		{#if currentStep > 1}
			<button class="footer-button secondary" on:click={prevStep}>
				Previous
			</button>
		{/if}
		
		{#if currentStep < totalSteps}
			<button class="footer-button primary" on:click={nextStep}>
				Next
			</button>
		{:else}
			<button 
				class="footer-button primary" 
				on:click={handleSubmit}
				disabled={isSubmitting}
			>
				{#if isSubmitting}
					<span class="loading-spinner"></span>
					Creating...
				{:else}
					Create Listing
				{/if}
			</button>
		{/if}
	</div>
</main>

<style>
	.create-listing-container {
		max-width: 414px;
		margin: 0 auto;
		min-height: 100vh;
		background: #f8fafc;
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
		background: rgba(255, 255, 255, 0.2);
		border: none;
		color: white;
		cursor: pointer;
		padding: 0.5rem;
		border-radius: 8px;
		transition: background-color 0.2s;
	}

	.back-button:hover {
		background: rgba(255, 255, 255, 0.3);
	}

	.page-title {
		font-size: 1.25rem;
		font-weight: 600;
		margin: 0;
	}

	.spacer {
		width: 40px;
	}

	.progress-container {
		background: white;
		padding: 1rem 1.5rem;
		border-bottom: 1px solid #e2e8f0;
	}

	.progress-bar {
		width: 100%;
		height: 6px;
		background: #e2e8f0;
		border-radius: 3px;
		overflow: hidden;
		margin-bottom: 0.5rem;
	}

	.progress-fill {
		height: 100%;
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		transition: width 0.3s ease;
	}

	.progress-text {
		text-align: center;
		font-size: 0.85rem;
		color: #718096;
	}

	.content {
		flex: 1;
		padding: 2rem 1.5rem 0;
		overflow-y: auto;
	}

	/* Error Banner */
	.error-banner {
		background: #fed7d7;
		border: 1px solid #feb2b2;
		border-radius: 8px;
		padding: 1rem;
		margin-bottom: 1.5rem;
		display: flex;
		align-items: center;
		gap: 0.75rem;
	}

	.error-icon {
		font-size: 1.25rem;
		flex-shrink: 0;
	}

	.error-message {
		color: #c53030;
		font-weight: 500;
		flex: 1;
	}

	.step-content {
		margin-bottom: 6rem;
	}

	.step-header {
		text-align: center;
		margin-bottom: 2rem;
	}

	.step-title {
		font-size: 1.5rem;
		font-weight: 600;
		color: #2d3748;
		margin: 0 0 0.5rem;
	}

	.step-subtitle {
		color: #718096;
		font-size: 1rem;
		margin: 0;
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



	.error-message {
		display: block;
		font-size: 0.8rem;
		color: #e53e3e;
		margin-top: 0.25rem;
	}

	.form-help {
		font-size: 0.8rem;
		color: #a0aec0;
		margin-top: 0.25rem;
	}

	/* Currency Selection */
	.currency-search {
		position: relative;
		margin-bottom: 1rem;
	}

	.search-input {
		width: 100%;
		padding: 0.875rem 1rem 0.875rem 3rem;
		border: 2px solid #e2e8f0;
		border-radius: 12px;
		font-size: 1rem;
		box-sizing: border-box;
	}

	.search-icon {
		position: absolute;
		left: 1rem;
		top: 50%;
		transform: translateY(-50%);
		color: #a0aec0;
	}

	.currency-grid {
		display: grid;
		grid-template-columns: 1fr;
		gap: 0.75rem;
		margin-bottom: 1rem;
	}

	.currency-option {
		background: white;
		border: 2px solid #e2e8f0;
		border-radius: 12px;
		padding: 1rem;
		cursor: pointer;
		display: flex;
		align-items: center;
		gap: 1rem;
		transition: border-color 0.2s, transform 0.2s;
		text-align: left;
	}

	.currency-option:hover {
		border-color: #667eea;
		transform: translateY(-1px);
	}

	.currency-flag {
		min-width: 2rem;
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.flag-image, .selected-flag {
		width: 24px;
		height: 18px;
		object-fit: cover;
		border-radius: 2px;
		border: 1px solid #e2e8f0;
	}

	.currency-code {
		font-weight: 600;
		color: #2d3748;
		font-size: 1rem;
	}

	.currency-name {
		color: #718096;
		font-size: 0.9rem;
	}

	.show-more-button {
		width: 100%;
		background: none;
		border: 2px dashed #cbd5e0;
		color: #667eea;
		padding: 1rem;
		border-radius: 12px;
		cursor: pointer;
		font-weight: 500;
		transition: border-color 0.2s;
	}

	.show-more-button:hover {
		border-color: #667eea;
	}

	.selected-currency {
		background: white;
		border: 2px solid #667eea;
		border-radius: 12px;
		padding: 1rem;
		display: flex;
		justify-content: space-between;
		align-items: center;
	}

	.selected-currency-display {
		display: flex;
		align-items: center;
		gap: 0.75rem;
	}

	.selected-flag-image {
		width: 24px;
		height: 18px;
		object-fit: cover;
		border-radius: 2px;
		border: 1px solid #e2e8f0;
	}

	.selected-code {
		font-weight: 600;
		color: #2d3748;
		font-size: 1rem;
	}

	.selected-name {
		color: #718096;
		font-size: 0.9rem;
	}

	.change-currency-button {
		background: none;
		border: none;
		color: #667eea;
		cursor: pointer;
		font-weight: 500;
		text-decoration: underline;
	}

	/* Amount Input */
	.amount-input-container {
		position: relative;
	}

	.amount-input {
		padding-right: 4rem;
	}

	.currency-suffix {
		position: absolute;
		right: 1rem;
		top: 50%;
		transform: translateY(-50%);
		color: #718096;
		font-weight: 500;
		pointer-events: none;
	}

	/* Radio Options */
	.meeting-options {
		display: flex;
		flex-direction: column;
		gap: 0.75rem;
	}

	.radio-option {
		display: flex;
		align-items: center;
		cursor: pointer;
		padding: 1rem;
		background: white;
		border: 2px solid #e2e8f0;
		border-radius: 12px;
		transition: border-color 0.2s;
	}

	.radio-option:hover {
		border-color: #cbd5e0;
	}

	.radio-input {
		margin-right: 0.75rem;
		accent-color: #667eea;
	}

	.radio-text {
		font-size: 0.95rem;
		color: #4a5568;
	}

	/* Exchange Preview */
	.exchange-preview {
		margin-top: 1rem;
		padding: 1rem;
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		border-radius: 12px;
		color: white;
	}

	.exchange-calculation {
		display: flex;
		align-items: center;
		justify-content: center;
		gap: 0.75rem;
		font-size: 1.1rem;
		font-weight: 600;
		margin-bottom: 0.5rem;
	}

	.from-amount, .to-amount {
		font-weight: 700;
	}

	.arrow {
		font-size: 1.2rem;
		opacity: 0.8;
	}

	.exchange-note {
		font-size: 0.85rem;
		opacity: 0.9;
		text-align: center;
	}

	/* Location Detection */
	.location-detector {
		border: 2px dashed #cbd5e0;
		border-radius: 12px;
		padding: 1.5rem;
		text-align: center;
		margin-bottom: 1rem;
	}

	.location-prompt {
		display: flex;
		align-items: center;
		gap: 1rem;
		margin-bottom: 1rem;
		text-align: left;
	}

	.location-icon {
		font-size: 2rem;
		flex-shrink: 0;
	}

	.location-text h3 {
		margin: 0 0 0.25rem 0;
		font-size: 1rem;
		font-weight: 600;
		color: #2d3748;
	}

	.location-text p {
		margin: 0;
		font-size: 0.9rem;
		color: #718096;
	}

	.location-detect-btn {
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		color: white;
		border: none;
		padding: 0.75rem 1.5rem;
		border-radius: 8px;
		font-weight: 600;
		cursor: pointer;
		transition: transform 0.2s;
	}

	.location-detect-btn:hover {
		transform: translateY(-1px);
	}

	.location-detecting {
		display: flex;
		align-items: center;
		gap: 0.75rem;
		padding: 1rem;
		background: #f7fafc;
		border-radius: 8px;
		color: #4a5568;
	}

	.spinner {
		width: 20px;
		height: 20px;
		border: 2px solid #e2e8f0;
		border-top: 2px solid #667eea;
		border-radius: 50%;
		animation: spin 1s linear infinite;
	}

	@keyframes spin {
		0% { transform: rotate(0deg); }
		100% { transform: rotate(360deg); }
	}

	.location-detected {
		margin-bottom: 1rem;
	}

	.location-confirmed {
		display: flex;
		align-items: center;
		gap: 0.75rem;
		padding: 1rem;
		background: #f0fff4;
		border: 1px solid #9ae6b4;
		border-radius: 8px;
		color: #276749;
	}

	.location-change-btn {
		background: none;
		border: none;
		color: #667eea;
		cursor: pointer;
		font-weight: 500;
		text-decoration: underline;
		margin-left: auto;
	}

	/* Listing Preview */
	.listing-preview {
		background: white;
		border: 2px solid #e2e8f0;
		border-radius: 12px;
		padding: 1.5rem;
		margin-bottom: 1.5rem;
	}

	.preview-header {
		text-align: center;
		margin-bottom: 1.5rem;
		padding-bottom: 1rem;
		border-bottom: 1px solid #e2e8f0;
	}

	.preview-currency {
		display: flex;
		align-items: center;
		justify-content: center;
		gap: 0.5rem;
		margin-bottom: 0.5rem;
	}

	.preview-flag-image {
		width: 28px;
		height: 21px;
		object-fit: cover;
		border-radius: 3px;
		border: 1px solid #e2e8f0;
	}

	.preview-amount {
		font-size: 1.5rem;
		font-weight: 600;
		color: #2d3748;
	}

	.preview-rate {
		color: #667eea;
		font-weight: 500;
	}

	.preview-details {
		display: flex;
		flex-direction: column;
		gap: 0.75rem;
	}

	.preview-item {
		display: flex;
		justify-content: space-between;
		align-items: center;
	}

	.preview-label {
		font-weight: 500;
		color: #4a5568;
		font-size: 0.9rem;
	}

	.preview-value {
		color: #718096;
		font-size: 0.9rem;
	}



	/* Footer Actions */
	.footer-actions {
		background: white;
		border-top: 1px solid #e2e8f0;
		padding: 1rem 1.5rem;
		display: flex;
		gap: 1rem;
		position: sticky;
		bottom: 0;
	}

	.footer-button {
		flex: 1;
		padding: 1rem;
		border: none;
		border-radius: 12px;
		font-size: 1rem;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.3s ease;
		display: flex;
		align-items: center;
		justify-content: center;
		gap: 0.5rem;
	}

	.footer-button.primary {
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		color: white;
		box-shadow: 0 4px 15px rgba(102, 126, 234, 0.3);
	}

	.footer-button.primary:hover:not(:disabled) {
		transform: translateY(-2px);
		box-shadow: 0 8px 25px rgba(102, 126, 234, 0.4);
	}

	.footer-button.secondary {
		background: #e2e8f0;
		color: #4a5568;
	}

	.footer-button.secondary:hover {
		background: #cbd5e0;
	}

	.footer-button:disabled {
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

	/* Responsive adjustments */
	@media (max-width: 375px) {
		.create-listing-container {
			max-width: 375px;
		}
		
		.content {
			padding: 1.5rem 1rem 0;
		}
		
		.footer-actions {
			padding: 1rem;
		}
		
		.currency-grid {
			grid-template-columns: 1fr;
			gap: 0.5rem;
		}
	}

	@media (max-width: 320px) {
		.create-listing-container {
			max-width: 320px;
		}
		
		.header {
			padding: 1rem;
		}
		
		.progress-container {
			padding: 1rem;
		}
		
		.content {
			padding: 1.25rem 0.75rem 0;
		}
		
		.step-title {
			font-size: 1.3rem;
		}
		
		.footer-actions {
			flex-direction: column;
		}
		
		.footer-button {
			width: 100%;
		}
	}
</style>