<script>
	import { onMount } from 'svelte';
	import { browser } from '$app/environment';
	
	let L;
	let mapContainer;
	let map;
	let markerClusterGroup;
	let listings = [];
	let isLoading = true;
	let selectedListing = null;
	let searchQuery = '';
	let filterCurrency = '';
	let filterRadius = 10;
	
	const DEFAULT_CENTER = [37.7749, -122.4194]; // San Francisco
	const DEFAULT_ZOOM = 12;
	
	onMount(async () => {
		// Only run on browser
		if (!browser) return;
		
		// Dynamically import Leaflet
		try {
			L = (await import('leaflet')).default;
			await import('leaflet/dist/leaflet.css');
			await import('leaflet.markercluster');
			await import('leaflet.markercluster/dist/MarkerCluster.css');
			await import('leaflet.markercluster/dist/MarkerCluster.Default.css');
		} catch (e) {
			console.error('Failed to import Leaflet:', e);
			return;
		}
		
		// Wait for next tick to ensure DOM is ready
		await new Promise(resolve => setTimeout(resolve, 0));
		
		if (!mapContainer) {
			console.error('Map container not found');
			return;
		}
		
		try {
			// Initialize map
			map = L.map(mapContainer).setView(DEFAULT_CENTER, DEFAULT_ZOOM);
			
			// Add OpenStreetMap tiles
			L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
				attribution: '© OpenStreetMap contributors',
				maxZoom: 19,
			}).addTo(map);
			
			// Initialize marker cluster group
			markerClusterGroup = L.markerClusterGroup({
				chunkedLoading: true,
				maxClusterRadius: 80,
			});
			map.addLayer(markerClusterGroup);
			
			// Load listings
			await loadListings();
			
			// Handle map click to deselect
			map.on('click', () => {
				selectedListing = null;
			});
		} catch (error) {
			console.error('Map initialization error:', error);
		}
	});
	
	async function loadListings() {
		try {
			isLoading = true;
			
			// Build query parameters
			const params = new URLSearchParams();
			if (searchQuery) params.append('location', searchQuery);
			if (filterCurrency) params.append('currency', filterCurrency);
			
			const response = await fetch(`http://localhost:9000/Listings/GetListingsForMap?${params.toString()}`);
			const data = await response.json();
			
			if (data.success && data.listings) {
				listings = data.listings;
				updateMarkers();
			} else {
				console.error('Error loading listings:', data.error);
			}
		} catch (error) {
			console.error('Error loading listings:', error);
		} finally {
			isLoading = false;
		}
	}
	
	function updateMarkers() {
		// Clear existing markers
		markerClusterGroup.clearLayers();
		
		// Add markers for each listing
		listings.forEach(listing => {
			if (listing.latitude && listing.longitude) {
				const marker = L.marker([listing.latitude, listing.longitude]);
				
				// Create popup content
				const popupContent = `
					<div class="listing-popup">
						<h3>${listing.currency} ${listing.amount}</h3>
						<p><strong>Location:</strong> ${listing.location}</p>
						<p><strong>Accepts:</strong> ${listing.accept_currency}</p>
						<p><strong>Preference:</strong> ${listing.meeting_preference}</p>
						<button class="view-btn" onclick="window.location.href='/listing/${listing.listing_id}'">
							View Listing
						</button>
					</div>
				`;
				
				marker.bindPopup(popupContent);
				
				// Add click handler
				marker.on('click', (e) => {
					selectedListing = listing;
					e.target.openPopup();
				});
				
				markerClusterGroup.addLayer(marker);
			}
		});
	}
	
	function handleSearch() {
		loadListings();
	}
	
	function zoomToListing(listing) {
		if (listing.latitude && listing.longitude) {
			map.setView([listing.latitude, listing.longitude], 15);
			selectedListing = listing;
		}
	}
	
	function resetView() {
		map.setView(DEFAULT_CENTER, DEFAULT_ZOOM);
		selectedListing = null;
	}
</script>

<div class="map-container">
	<div class="map-wrapper">
		<div class="map" bind:this={mapContainer}></div>
		
		<!-- Search Panel -->
		<div class="search-panel">
			<h3>Find Listings</h3>
			
			<div class="form-group">
				<label for="location">Location</label>
				<input 
					type="text" 
					id="location"
					placeholder="City or area..."
					bind:value={searchQuery}
					on:keydown={(e) => e.key === 'Enter' && handleSearch()}
				/>
			</div>
			
			<div class="form-group">
				<label for="currency">Currency</label>
				<select id="currency" bind:value={filterCurrency}>
					<option value="">All Currencies</option>
					<option value="USD">USD</option>
					<option value="EUR">EUR</option>
					<option value="GBP">GBP</option>
					<option value="JPY">JPY</option>
					<option value="CAD">CAD</option>
					<option value="AUD">AUD</option>
				</select>
			</div>
			
			<div class="form-group">
				<label for="radius">Search Radius</label>
				<input 
					type="range" 
					id="radius"
					min="1"
					max="100"
					bind:value={filterRadius}
				/>
				<span class="radius-value">{filterRadius} km</span>
			</div>
			
			<div class="button-group">
				<button class="btn btn-primary" on:click={handleSearch}>
					{#if isLoading}
						Loading...
					{:else}
						Search
					{/if}
				</button>
				<button class="btn btn-secondary" on:click={resetView}>
					Reset View
				</button>
			</div>
			
			{#if listings.length > 0}
				<p class="listing-count">
					Found {listings.length} listing{listings.length !== 1 ? 's' : ''}
				</p>
			{/if}
		</div>
		
		<!-- Selected Listing Info -->
		{#if selectedListing}
			<div class="listing-info-panel">
				<button class="close-btn" on:click={() => selectedListing = null}>×</button>
				
				<div class="listing-details">
					<h2>{selectedListing.currency} {selectedListing.amount}</h2>
					
					<div class="detail-row">
						<span class="label">Location:</span>
						<span class="value">{selectedListing.location}</span>
					</div>
					
					<div class="detail-row">
						<span class="label">Accepts:</span>
						<span class="value">{selectedListing.accept_currency}</span>
					</div>
					
					<div class="detail-row">
						<span class="label">Meeting:</span>
						<span class="value">{selectedListing.meeting_preference}</span>
					</div>
					
					<div class="detail-row">
						<span class="label">Radius:</span>
						<span class="value">{selectedListing.location_radius} km</span>
					</div>
					
					{#if selectedListing.available_until}
						<div class="detail-row">
							<span class="label">Available Until:</span>
							<span class="value">
								{new Date(selectedListing.available_until).toLocaleDateString()}
							</span>
						</div>
					{/if}
					
					<div class="button-group">
						<a href="/listing/{selectedListing.listing_id}" class="btn btn-primary">
							View Full Listing
						</a>
					</div>
				</div>
			</div>
		{/if}
	</div>
</div>

<style>
	.map-container {
		width: 100%;
		height: 100vh;
		display: flex;
	}
	
	.map-wrapper {
		position: relative;
		width: 100%;
		height: 100%;
	}
	
	.map {
		width: 100%;
		height: 100%;
		z-index: 1;
	}
	
	.search-panel {
		position: absolute;
		top: 20px;
		left: 20px;
		background: white;
		padding: 20px;
		border-radius: 8px;
		box-shadow: 0 2px 10px rgba(0, 0, 0, 0.2);
		z-index: 10;
		width: 300px;
		max-height: 80vh;
		overflow-y: auto;
		font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
	}
	
	.search-panel h3 {
		margin: 0 0 20px 0;
		font-size: 18px;
		color: #333;
	}
	
	.form-group {
		margin-bottom: 15px;
		display: flex;
		flex-direction: column;
	}
	
	.form-group label {
		margin-bottom: 5px;
		font-weight: 500;
		font-size: 14px;
		color: #555;
	}
	
	.form-group input[type="text"],
	.form-group select {
		padding: 8px 10px;
		border: 1px solid #ddd;
		border-radius: 4px;
		font-size: 14px;
		font-family: inherit;
	}
	
	.form-group input[type="range"] {
		width: 100%;
	}
	
	.radius-value {
		margin-top: 5px;
		font-size: 12px;
		color: #888;
	}
	
	.button-group {
		display: flex;
		gap: 10px;
		margin-top: 15px;
	}
	
	.btn {
		flex: 1;
		padding: 10px 15px;
		border: none;
		border-radius: 4px;
		font-size: 14px;
		font-weight: 500;
		cursor: pointer;
		transition: background-color 0.3s;
		font-family: inherit;
	}
	
	.btn-primary {
		background-color: #2563eb;
		color: white;
	}
	
	.btn-primary:hover {
		background-color: #1d4ed8;
	}
	
	.btn-secondary {
		background-color: #e5e7eb;
		color: #333;
	}
	
	.btn-secondary:hover {
		background-color: #d1d5db;
	}
	
	.listing-count {
		margin-top: 10px;
		font-size: 14px;
		color: #666;
	}
	
	.listing-info-panel {
		position: absolute;
		bottom: 20px;
		right: 20px;
		background: white;
		padding: 20px;
		border-radius: 8px;
		box-shadow: 0 2px 10px rgba(0, 0, 0, 0.2);
		z-index: 10;
		width: 320px;
		max-height: 60vh;
		overflow-y: auto;
	}
	
	.close-btn {
		position: absolute;
		top: 10px;
		right: 10px;
		background: none;
		border: none;
		font-size: 24px;
		color: #999;
		cursor: pointer;
	}
	
	.close-btn:hover {
		color: #333;
	}
	
	.listing-details {
		margin-top: 10px;
	}
	
	.listing-details h2 {
		margin: 0 0 15px 0;
		font-size: 20px;
		color: #333;
	}
	
	.detail-row {
		display: flex;
		justify-content: space-between;
		margin-bottom: 10px;
		font-size: 14px;
	}
	
	.detail-row .label {
		font-weight: 500;
		color: #666;
	}
	
	.detail-row .value {
		color: #333;
		text-align: right;
		flex: 1;
		margin-left: 10px;
	}
	
	.listing-popup {
		padding: 5px;
		font-size: 14px;
	}
	
	.listing-popup h3 {
		margin: 0 0 10px 0;
	}
	
	.listing-popup p {
		margin: 5px 0;
	}
	
	.listing-popup .view-btn {
		margin-top: 10px;
		padding: 8px 12px;
		background-color: #2563eb;
		color: white;
		border: none;
		border-radius: 4px;
		cursor: pointer;
		font-size: 12px;
		width: 100%;
	}
	
	.listing-popup .view-btn:hover {
		background-color: #1d4ed8;
	}
	
	/* Responsive */
	@media (max-width: 768px) {
		.search-panel {
			width: 280px;
			max-height: 50vh;
		}
		
		.listing-info-panel {
			width: 280px;
			max-height: 40vh;
			bottom: 10px;
			right: 10px;
		}
	}
</style>
