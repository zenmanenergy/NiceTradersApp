import { error } from '@sveltejs/kit';

export async function load({ params, fetch }) {
	const transactionId = params.id;
	
	try {
		// Fetch transaction data
		const txRes = await fetch('http://localhost:9000/Admin/GetTransactionById', {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ transactionId })
		});
		const txData = await txRes.json();
		
		if (!txData.success) {
			throw error(404, 'Transaction not found');
		}
		
		const transaction = txData.transaction;
		let transactionBuyer = null;
		let transactionSeller = null;
		let transactionListing = null;
		
		// Fetch buyer
		if (transaction.user_id) {
			const buyerRes = await fetch('http://localhost:9000/Admin/GetUserById', {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ user_id: transaction.user_id })
			});
			const buyerData = await buyerRes.json();
			if (buyerData.success) {
				transactionBuyer = buyerData.user;
			}
		}
		
		// Fetch listing and seller
		if (transaction.listing_id) {
			const listingRes = await fetch('http://localhost:9000/Admin/GetListingById', {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ listingId: transaction.listing_id })
			});
			const listingData = await listingRes.json();
			
			if (listingData.success) {
				transactionListing = listingData.listing;
				
				// Fetch seller
				if (listingData.listing.user_id) {
					const sellerRes = await fetch('http://localhost:9000/Admin/GetUserById', {
						method: 'POST',
						headers: { 'Content-Type': 'application/json' },
						body: JSON.stringify({ user_id: listingData.listing.user_id })
					});
					const sellerData = await sellerRes.json();
					if (sellerData.success) {
						transactionSeller = sellerData.user;
					}
				}
			}
		}
		
		return {
			transaction,
			transactionBuyer,
			transactionSeller,
			transactionListing
		};
	} catch (err) {
		console.error('Error loading transaction:', err);
		throw error(500, 'Failed to load transaction');
	}
}
