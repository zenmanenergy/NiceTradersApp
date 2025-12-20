export async function load({ params }) {
	const listingId = params.id;
	
	try {
		const listingRes = await fetch(`http://localhost:9000/Admin/GetListingById`, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ listingId })
		});
		const listingData = await listingRes.json();
		
		const ownerRes = await fetch(`http://localhost:9000/Admin/GetUserById`, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ user_id: listingData.listing.user_id })
		});
		const ownerData = await ownerRes.json();
		
		const purchasesRes = await fetch(`http://localhost:9000/Admin/GetListingPurchases`, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ listingId })
		});
		const purchasesData = await purchasesRes.json();
		
		const messagesRes = await fetch(`http://localhost:9000/Admin/GetListingMessages`, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ listingId })
		});
		const messagesData = await messagesRes.json();
		
		return {
			listing: listingData.listing,
			owner: ownerData.user,
			purchases: purchasesData.purchases || [],
			messages: messagesData.messages || []
		};
	} catch (err) {
		console.error('Error loading listing:', err);
		return {
			listing: null,
			owner: null,
			purchases: [],
			messages: [],
			error: err.message
		};
	}
}

