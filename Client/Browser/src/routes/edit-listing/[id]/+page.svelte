<script>
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';
	import { onMount } from 'svelte';
	import { Session } from '../../../Session.js';

	// Get listing ID from URL params
	$: listingId = $page.params.id;
	
	// Initialize session management
	onMount(async () => {
		await Session.handleSession();
		Session.GetSessionId(); // This sets Session.SessionId
		const sessionId = Session.SessionId;
		
		if (!sessionId) {
			goto('/login');
			return;
		}
		
		// Load listing data here if needed
		// handleGetListing(listingId, sessionId, callback);
	});

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
	
	// Form data - will be populated from existing listing
	let formData = {
		currency: '',
		amount: '',
		acceptCurrency: '',
		location: '',
		locationRadius: '5',
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
	let locationStatus = 'detected'; // Start as detected since we're editing
	let isDeleting = false;

	// Mock listing data (in real app, would fetch from API)
	const mockListings = {
		'1': {
			id: 1,
			haveCurrency: 'USD',
			haveAmount: 500,
			wantCurrency: 'EUR',
			wantAmount: 425,
			location: 'San Francisco, CA (37.7749, -122.4194)',
			radius: 5,
			meetingPreference: 'public',
			availableUntil: '2024-11-17',
			notes: 'Prefer to meet during weekdays'
		},
		'2': {
			id: 2,
			haveCurrency: 'GBP',
			haveAmount: 300,
			wantCurrency: 'USD',
			wantAmount: 412,
			location: 'San Francisco, CA (37.7749, -122.4194)',
			radius: 10,
			meetingPreference: 'flexible',
			availableUntil: '2024-11-15',
			notes: ''
		}
	};

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
		goto('/dashboard');
	}

	function nextStep() {
		if (validateCurrentStep()) {
			if (currentStep < totalSteps) {
				currentStep++;
				errors = {};
			}
		}
	}

	function prevStep() {
		if (currentStep > 1) {
			currentStep--;
			errors = {};
		}
	}

	function validateCurrentStep() {
		errors = {};
		
		if (currentStep === 1) {
			if (!formData.currency) {
				errors.currency = 'Please select a currency';
				return false;
			}
			if (!formData.amount || parseFloat(formData.amount) <= 0) {
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

	// Mock exchange rate calculation
	function calculateReceiveAmount() {
		if (!formData.amount || !formData.currency || !formData.acceptCurrency) return '0';
		
		const rates = {
			'USD': 1.0, 'EUR': 0.85, 'GBP': 0.73, 'JPY': 110.0, 'CAD': 1.25,
			'AUD': 1.35, 'CHF': 0.92, 'CNY': 6.45, 'SEK': 8.5, 'NZD': 1.4
		};
		
		const fromRate = rates[formData.currency] || 1.0;
		const toRate = rates[formData.acceptCurrency] || 1.0;
		const usdAmount = parseFloat(formData.amount) / fromRate;
		const targetAmount = usdAmount * toRate;
		
		return Math.round(targetAmount).toString();
	}
	
	async function handleSubmit() {
		if (!validateCurrentStep()) return;
		
		isSubmitting = true;
		
		// Simulate API call
		setTimeout(() => {
			isSubmitting = false;
			alert(`Listing updated successfully!\n\nUpdated listing: ${formData.amount} ${formData.currency} for ${calculateReceiveAmount()} ${formData.acceptCurrency}\n\n(This is just a prototype)`);
			goto('/dashboard');
		}, 2000);
	}

	function handleUseLocation() {
		// For editing, location is already detected
		locationStatus = 'detected';
	}

	async function handleDeleteListing() {
		if (!confirm('Are you sure you want to delete this listing? This action cannot be undone.')) {
			return;
		}

		isDeleting = true;

		// Simulate API call
		setTimeout(() => {
			isDeleting = false;
			alert('Listing deleted successfully!');
			goto('/dashboard');
		}, 1500);
	}

	// Load existing listing data
	onMount(() => {
		const listing = mockListings[listingId];
		if (listing) {
			formData = {
				currency: listing.haveCurrency,
				amount: listing.haveAmount.toString(),
				acceptCurrency: listing.wantCurrency,
				location: listing.location,
				locationRadius: listing.radius.toString(),
				meetingPreference: listing.meetingPreference,
				availableUntil: listing.availableUntil
			};
		} else {
			// Listing not found, redirect back
			alert('Listing not found');
			goto('/dashboard');
		}
	});
</script>

<svelte:head>
	<title>Edit Listing - NICE Traders</title>
	<meta name="description" content="Edit your currency exchange listing" />
</svelte:head>

<main class="edit-listing-container">
	<div class="header">
		<button class="back-button" on:click={goBack} aria-label="Go back to dashboard">
			<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
				<polyline points="15,18 9,12 15,6"></polyline>
			</svg>
		</button>
		<h1 class="page-title">Edit Listing</h1>
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
						<!-- Search -->
						<div class="search-container">
							<input 
								type="text" 
								bind:value={searchQuery}
								class="search-input"
								placeholder="Search currencies..."
								on:input={() => {}}
							/>
						</div>

						<!-- Currency options -->
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
										<span class="currency-code">{currency.code}</span>
										<span class="currency-name">{currency.name}</span>
									</div>
								</button>
							{/each}
						</div>

						{#if !showAllCurrencies}
							<button class="show-more-btn" on:click={() => showAllCurrencies = true}>
								Show all currencies
							</button>
						{/if}
					{:else}
						<!-- Selected currency -->
						<div class="selected-currency">
							<div class="selected-currency-display">
								<img src={getFlagImage(formData.currency)} alt="{formData.currency} flag" class="selected-flag-image" />
								<span class="selected-code">{formData.currency}</span>
								<span class="selected-name">{getCurrencyName(formData.currency)}</span>
							</div>
							<button class="change-currency-button" on:click={() => formData.currency = ''}>Change</button>
						</div>
					{/if}
					{#if errors.currency}
						<span class="error-message">{errors.currency}</span>
					{/if}
				</div>

				<!-- Amount Input -->
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
							step="1"
							min="1"
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
					<p class="step-subtitle">Update your meeting preferences</p>
				</div>

				<!-- Location -->
				<div class="form-group">
					<label class="form-label">Your Location</label>
					
					<div class="location-detected">
						<div class="location-confirmed">
							<span class="location-icon">✅</span>
							<span class="location-text">Location detected</span>
							<button class="location-change-btn" on:click={handleUseLocation}>Update</button>
						</div>
					</div>
					
					<div class="form-help">Your exact location stays private - others see general area only</div>
				</div>

				<!-- Distance Radius -->
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
							<span class="radio-text">Flexible locations</span>
						</label>
					</div>
				</div>

				<!-- Available Until -->
				<div class="form-group">
					<label for="available-until" class="form-label">Available Until</label>
					<input 
						type="date" 
						id="available-until"
						bind:value={formData.availableUntil}
						class="form-input"
						class:error={errors.availableUntil}
						min={new Date().toISOString().split('T')[0]}
					/>
					{#if errors.availableUntil}
						<span class="error-message">{errors.availableUntil}</span>
					{/if}
					<div class="form-help">When should this listing expire?</div>
				</div>

				<!-- Allow Offers -->

			</div>

		{:else if currentStep === 3}
			<!-- Step 3: Review and Submit -->
			<div class="step-content">
				<div class="step-header">
					<h2 class="step-title">Review your changes</h2>
					<p class="step-subtitle">Make sure everything looks correct</p>
				</div>

				<div class="listing-preview">
					<div class="preview-header">
						<div class="preview-currency">
							<img src={getFlagImage(formData.currency)} alt="{formData.currency} flag" class="preview-flag-image" />
							<span class="preview-amount">{formData.amount} {formData.currency}</span>
						</div>
						<div class="preview-rate">
							Market Rate → {calculateReceiveAmount()} {formData.acceptCurrency}
						</div>
					</div>

					<div class="preview-details">
						<div class="preview-item">
							<span class="preview-label">Meeting Distance:</span>
							<span class="preview-value">Within {formData.locationRadius} miles</span>
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
				Back
			</button>
		{/if}
		
		{#if currentStep < totalSteps}
			<button class="footer-button primary" on:click={nextStep} class:full-width={currentStep === 1}>
				Next
			</button>
		{:else}
			<button 
				class="footer-button primary" 
				on:click={handleSubmit}
				disabled={isSubmitting}
			>
				{#if isSubmitting}
					Updating...
				{:else}
					Update Listing
				{/if}
			</button>
		{/if}
	</div>

	<!-- Delete Section -->
	<div class="delete-section">
		<div class="delete-warning">
			<h3>Danger Zone</h3>
			<p>Once you delete this listing, there is no going back. Please be certain.</p>
		</div>
		<button 
			class="delete-button"
			on:click={handleDeleteListing}
			disabled={isDeleting}
		>
			{#if isDeleting}
				Deleting...
			{:else}
				Delete This Listing
			{/if}
		</button>
	</div>
</main>

<style>
	.edit-listing-container {
		max-width: 414px;
		margin: 0 auto;
		min-height: 100vh;
		background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
		display: flex;
		flex-direction: column;
		box-shadow: 0 0 20px rgba(0, 0, 0, 0.1);
	}

	.header {
		display: flex;
		align-items: center;
		padding: 1rem;
		background: rgba(255, 255, 255, 0.1);
		backdrop-filter: blur(10px);
		border-bottom: 1px solid rgba(255, 255, 255, 0.2);
	}

	.back-button {
		background: rgba(255, 255, 255, 0.2);
		border: none;
		color: white;
		padding: 0.5rem;
		border-radius: 8px;
		cursor: pointer;
		display: flex;
		align-items: center;
		justify-content: center;
		transition: background 0.2s;
	}

	.back-button:hover {
		background: rgba(255, 255, 255, 0.3);
	}

	.page-title {
		color: white;
		font-size: 1.5rem;
		font-weight: 600;
		margin: 0 0 0 1rem;
	}

	.spacer {
		flex: 1;
	}

	.progress-container {
		padding: 1rem;
		background: rgba(255, 255, 255, 0.1);
	}

	.progress-bar {
		width: 100%;
		height: 6px;
		background: rgba(255, 255, 255, 0.2);
		border-radius: 3px;
		overflow: hidden;
		margin-bottom: 0.5rem;
	}

	.progress-fill {
		height: 100%;
		background: white;
		border-radius: 3px;
		transition: width 0.3s ease;
	}

	.progress-text {
		color: white;
		font-size: 0.9rem;
		text-align: center;
		opacity: 0.9;
	}

	.content {
		flex: 1;
		padding: 1rem;
		overflow-y: auto;
	}

	.step-content {
		background: rgba(255, 255, 255, 0.95);
		border-radius: 16px;
		padding: 1.5rem;
		margin-bottom: 1rem;
		box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
	}

	.step-header {
		text-align: center;
		margin-bottom: 2rem;
	}

	.step-title {
		color: #2d3748;
		font-size: 1.5rem;
		font-weight: 600;
		margin: 0 0 0.5rem 0;
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
		font-weight: 600;
		color: #2d3748;
		margin-bottom: 0.5rem;
		font-size: 1rem;
	}

	.search-container {
		margin-bottom: 1rem;
	}

	.search-input {
		width: 100%;
		padding: 0.875rem 1rem;
		border: 2px solid #e2e8f0;
		border-radius: 12px;
		font-size: 1rem;
		transition: border-color 0.2s, box-shadow 0.2s;
		background: white;
		box-sizing: border-box;
	}

	.search-input:focus {
		outline: none;
		border-color: #667eea;
		box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
	}

	.currency-grid {
		display: grid;
		gap: 0.75rem;
		margin-bottom: 1rem;
	}

	.currency-option {
		display: flex;
		align-items: center;
		gap: 0.75rem;
		padding: 1rem;
		background: white;
		border: 2px solid #e2e8f0;
		border-radius: 12px;
		cursor: pointer;
		transition: all 0.2s;
		text-align: left;
		width: 100%;
	}

	.currency-option:hover {
		border-color: #cbd5e0;
		background: #f7fafc;
	}

	.currency-option:focus {
		outline: none;
		border-color: #667eea;
		box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
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

	.show-more-btn {
		width: 100%;
		background: none;
		border: 2px dashed #cbd5e0;
		color: #4a5568;
		padding: 1rem;
		border-radius: 12px;
		cursor: pointer;
		font-weight: 500;
		transition: all 0.2s;
	}

	.show-more-btn:hover {
		border-color: #667eea;
		color: #667eea;
		background: rgba(102, 126, 234, 0.05);
	}

	.selected-currency {
		display: flex;
		align-items: center;
		justify-content: space-between;
		padding: 1rem;
		background: #f0fff4;
		border: 2px solid #9ae6b4;
		border-radius: 12px;
		margin-bottom: 1rem;
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

	.change-currency-button, .change-btn {
		background: none;
		border: none;
		color: #667eea;
		cursor: pointer;
		font-weight: 500;
		text-decoration: underline;
	}

	.amount-input-container {
		position: relative;
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

	.amount-input {
		padding-right: 5rem;
		font-size: 1.2rem;
		font-weight: 600;
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

	.form-select {
		width: 100%;
		padding: 0.875rem 1rem;
		border: 2px solid #e2e8f0;
		border-radius: 12px;
		font-size: 1rem;
		background: white;
		cursor: pointer;
		transition: border-color 0.2s, box-shadow 0.2s;
		box-sizing: border-box;
	}

	.form-select:focus {
		outline: none;
		border-color: #667eea;
		box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
	}



	.error-message {
		display: block;
		font-size: 0.8rem;
		color: #e53e3e;
		margin-top: 0.25rem;
	}

	.form-help {
		font-size: 0.8rem;
		color: #718096;
		margin-top: 0.25rem;
	}

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

	.checkbox-label {
		display: flex;
		align-items: flex-start;
		cursor: pointer;
		gap: 0.75rem;
		padding: 1rem;
		background: white;
		border: 2px solid #e2e8f0;
		border-radius: 12px;
		transition: border-color 0.2s;
	}

	.checkbox-label:hover {
		border-color: #cbd5e0;
	}

	.checkbox-input {
		margin: 0;
		accent-color: #667eea;
		flex-shrink: 0;
		margin-top: 0.125rem;
	}

	.checkbox-text {
		font-size: 0.95rem;
		color: #4a5568;
		line-height: 1.4;
	}

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

	.listing-preview {
		background: white;
		border-radius: 16px;
		padding: 1.5rem;
		border: 2px solid #e2e8f0;
	}

	.preview-header {
		display: flex;
		align-items: center;
		justify-content: space-between;
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
		font-weight: 600;
		font-size: 0.9rem;
		text-align: center;
	}

	.preview-details {
		margin-bottom: 1rem;
	}

	.preview-item {
		display: flex;
		justify-content: space-between;
		margin-bottom: 0.75rem;
	}

	.preview-label {
		font-weight: 500;
		color: #4a5568;
		font-size: 0.9rem;
	}

	.preview-value {
		color: #2d3748;
		font-size: 0.9rem;
	}



	.footer-actions {
		display: flex;
		gap: 1rem;
		padding: 1rem;
		background: rgba(255, 255, 255, 0.1);
		backdrop-filter: blur(10px);
		border-top: 1px solid rgba(255, 255, 255, 0.2);
	}

	.footer-button {
		flex: 1;
		padding: 1rem;
		border: none;
		border-radius: 12px;
		font-weight: 600;
		font-size: 1rem;
		cursor: pointer;
		transition: all 0.2s;
		min-height: 3rem;
	}

	.footer-button.primary {
		background: white;
		color: #667eea;
	}

	.footer-button.primary:hover {
		background: #f7fafc;
		transform: translateY(-1px);
	}

	.footer-button.primary:disabled {
		opacity: 0.6;
		cursor: not-allowed;
		transform: none;
	}

	.footer-button.secondary {
		background: rgba(255, 255, 255, 0.2);
		color: white;
		border: 1px solid rgba(255, 255, 255, 0.3);
	}

	.footer-button.secondary:hover {
		background: rgba(255, 255, 255, 0.3);
	}

	.footer-button.full-width {
		width: 100%;
	}

	.delete-section {
		background: rgba(255, 255, 255, 0.95);
		margin: 1rem;
		border-radius: 16px;
		padding: 1.5rem;
		border: 2px solid #fed7d7;
	}

	.delete-warning {
		margin-bottom: 1rem;
	}

	.delete-warning h3 {
		color: #c53030;
		font-size: 1.1rem;
		font-weight: 600;
		margin: 0 0 0.5rem 0;
	}

	.delete-warning p {
		color: #718096;
		font-size: 0.9rem;
		margin: 0;
		line-height: 1.4;
	}

	.delete-button {
		width: 100%;
		padding: 0.875rem 1rem;
		background: #e53e3e;
		color: white;
		border: none;
		border-radius: 8px;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.2s;
	}

	.delete-button:hover {
		background: #c53030;
		transform: translateY(-1px);
	}

	.delete-button:disabled {
		opacity: 0.6;
		cursor: not-allowed;
		transform: none;
	}

	/* Mobile Responsive */
	@media (max-width: 480px) {
		.preview-header {
			flex-direction: column;
			gap: 1rem;
			text-align: center;
		}
	}
</style>