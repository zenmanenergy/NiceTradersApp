from _Lib import Database
from _Lib.Debugger import Debugger
from flask import Blueprint, request
from flask_cors import CORS, cross_origin
from .CreateListing import create_listing
from .GetListings import get_listings
from .GetListingById import get_listing_by_id
from .UpdateListing import update_listing
from .DeleteListing import delete_listing

blueprint = Blueprint('Listings', __name__)

@blueprint.route("/Listings/CreateListing", methods=['GET'])
@cross_origin()
def CreateListing():
	try:
		ListingData = request.args.to_dict()
		session_id = ListingData.get('session_id', None)
		Currency = ListingData.get('currency', None)
		Amount = ListingData.get('amount', None)
		AcceptCurrency = ListingData.get('acceptCurrency', None)
		Location = ListingData.get('location', None)
		Latitude = ListingData.get('latitude', None)
		Longitude = ListingData.get('longitude', None)
		LocationRadius = ListingData.get('locationRadius', '5')
		MeetingPreference = ListingData.get('meetingPreference', 'public')
		AvailableUntil = ListingData.get('availableUntil', None)
		WillRoundToNearestDollar = ListingData.get('willRoundToNearestDollar', 'false').lower() == 'true'
		
		result = create_listing(session_id, Currency, Amount, AcceptCurrency, Location, Latitude, Longitude, LocationRadius, MeetingPreference, AvailableUntil, WillRoundToNearestDollar)
		return result
	except Exception as e:
		return Debugger(e)

@blueprint.route("/Listings/GetListings", methods=['GET'])
@cross_origin()
def GetListings():
	try:
		FilterData = request.args.to_dict()
		Currency = FilterData.get('currency', None)
		AcceptCurrency = FilterData.get('acceptCurrency', None)
		Location = FilterData.get('location', None)
		MaxDistance = FilterData.get('maxDistance', None)
		Limit = FilterData.get('limit', '20')
		Offset = FilterData.get('offset', '0')
		CurrentUserId = FilterData.get('currentUserId', None)  # Optional: exclude current user's listings
		
		result = get_listings(Currency, AcceptCurrency, Location, MaxDistance, Limit, Offset, CurrentUserId)
		return result
	except Exception as e:
		return Debugger(e)

@blueprint.route("/Listings/GetListingById", methods=['GET'])
@cross_origin()
def GetListingById():
	try:
		ListingData = request.args.to_dict()
		ListingId = ListingData.get('listingId', None)
		
		result = get_listing_by_id(ListingId)
		return result
	except Exception as e:
		return Debugger(e)

@blueprint.route("/Listings/UpdateListing", methods=['GET'])
@cross_origin()
def UpdateListing():
	try:
		ListingData = request.args.to_dict()
		session_id = ListingData.get('session_id', None)
		ListingId = ListingData.get('listingId', None)
		Currency = ListingData.get('currency', None)
		Amount = ListingData.get('amount', None)
		AcceptCurrency = ListingData.get('acceptCurrency', None)
		Location = ListingData.get('location', None)
		Latitude = ListingData.get('latitude', None)
		Longitude = ListingData.get('longitude', None)
		LocationRadius = ListingData.get('locationRadius', None)
		MeetingPreference = ListingData.get('meetingPreference', None)
		AvailableUntil = ListingData.get('availableUntil', None)
		Status = ListingData.get('status', None)
		WillRoundToNearestDollar = ListingData.get('willRoundToNearestDollar', None)
		if WillRoundToNearestDollar is not None:
			WillRoundToNearestDollar = WillRoundToNearestDollar.lower() == 'true'
		
		result = update_listing(session_id, ListingId, Currency, Amount, AcceptCurrency, Location, Latitude, Longitude, LocationRadius, MeetingPreference, AvailableUntil, Status, WillRoundToNearestDollar)
		return result
	except Exception as e:
		return Debugger(e)

@blueprint.route("/Listings/DeleteListing", methods=['GET'])
@cross_origin()
def DeleteListing():
	try:
		ListingData = request.args.to_dict()
		session_id = ListingData.get('session_id', None)
		ListingId = ListingData.get('listingId', None)
		Permanent = ListingData.get('permanent', 'false')
		
		result = delete_listing(session_id, ListingId, Permanent)
		return result
	except Exception as e:
		return Debugger(e)

@blueprint.route("/Listings/GetListingsForMap", methods=['GET'])
@cross_origin()
def GetListingsForMap():
	"""Get listings with geographic data for map display"""
	try:
		from _Lib.Database import ConnectToDatabase
		import json
		from decimal import Decimal
		
		# Get query parameters
		currency = request.args.get('currency', None)
		location = request.args.get('location', None)
		accept_currency = request.args.get('acceptCurrency', None)
		limit = int(request.args.get('limit', 500))  # Max 500 for map performance
		
		cursor, connection = ConnectToDatabase()
		
		# Build query for listings with coordinates
		query = """
			SELECT 
				listing_id,
				user_id,
				currency,
				amount,
				accept_currency,
				location,
				latitude,
				longitude,
				location_radius,
				meeting_preference,
				will_round_to_nearest_dollar,
				available_until,
				status,
				geocoded_location,
				created_at,
				updated_at
			FROM listings
			WHERE status = 'active'
			AND latitude IS NOT NULL
			AND longitude IS NOT NULL
		"""
		
		params = []
		
		if currency:
			query += " AND currency = %s"
			params.append(currency)
		
		if accept_currency:
			query += " AND accept_currency = %s"
			params.append(accept_currency)
		
		if location:
			query += " AND (location LIKE %s OR geocoded_location LIKE %s)"
			location_search = f'%{location}%'
			params.extend([location_search, location_search])
		
		query += f" ORDER BY created_at DESC LIMIT {limit}"
		
		cursor.execute(query, params)
		listings = cursor.fetchall()
		
		cursor.close()
		connection.close()
		
		# Convert to list format and handle Decimal types
		listing_list = []
		for row in (listings or []):
			listing_dict = dict(row)
			
			# Convert Decimal to float
			if listing_dict.get('latitude'):
				listing_dict['latitude'] = float(listing_dict['latitude'])
			if listing_dict.get('longitude'):
				listing_dict['longitude'] = float(listing_dict['longitude'])
			if listing_dict.get('amount'):
				listing_dict['amount'] = float(listing_dict['amount'])
			
			# Convert datetime objects to strings for JSON
			if listing_dict.get('available_until'):
				listing_dict['available_until'] = listing_dict['available_until'].isoformat()
			if listing_dict.get('created_at'):
				listing_dict['created_at'] = listing_dict['created_at'].isoformat()
			if listing_dict.get('updated_at'):
				listing_dict['updated_at'] = listing_dict['updated_at'].isoformat()
			
			listing_list.append(listing_dict)
		
		return json.dumps({
			'success': True,
			'listings': listing_list,
			'count': len(listing_list)
		})
	except Exception as e:
		import json
		return json.dumps({
			'success': False,
			'error': str(e)
		})
		return result
	except Exception as e:
		return Debugger(e)