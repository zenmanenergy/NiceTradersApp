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
		SessionId = ListingData.get('SessionId', None)
		Currency = ListingData.get('currency', None)
		Amount = ListingData.get('amount', None)
		AcceptCurrency = ListingData.get('acceptCurrency', None)
		Location = ListingData.get('location', None)
		Latitude = ListingData.get('latitude', None)
		Longitude = ListingData.get('longitude', None)
		LocationRadius = ListingData.get('locationRadius', '5')
		MeetingPreference = ListingData.get('meetingPreference', 'public')
		AvailableUntil = ListingData.get('availableUntil', None)
		
		result = create_listing(SessionId, Currency, Amount, AcceptCurrency, Location, Latitude, Longitude, LocationRadius, MeetingPreference, AvailableUntil)
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
		
		result = get_listings(Currency, AcceptCurrency, Location, MaxDistance, Limit, Offset)
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
		SessionId = ListingData.get('SessionId', None)
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
		
		result = update_listing(SessionId, ListingId, Currency, Amount, AcceptCurrency, Location, Latitude, Longitude, LocationRadius, MeetingPreference, AvailableUntil, Status)
		return result
	except Exception as e:
		return Debugger(e)

@blueprint.route("/Listings/DeleteListing", methods=['GET'])
@cross_origin()
def DeleteListing():
	try:
		ListingData = request.args.to_dict()
		SessionId = ListingData.get('SessionId', None)
		ListingId = ListingData.get('listingId', None)
		Permanent = ListingData.get('permanent', 'false')
		
		result = delete_listing(SessionId, ListingId, Permanent)
		return result
	except Exception as e:
		return Debugger(e)