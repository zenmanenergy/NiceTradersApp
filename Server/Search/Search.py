from _Lib.Debugger import Debugger
from flask import Blueprint, request
from flask_cors import cross_origin
from .SearchListings import search_listings
from .GetSearchFilters import get_search_filters
from .GetPopularSearches import get_popular_searches
from .SearchListingsInRadius import search_listings_in_radius

# Create the Search blueprint
search_bp = Blueprint('search', __name__)

@search_bp.route('/Search/SearchListings', methods=['GET'])
@cross_origin()
def SearchListings():
    """Handle listing search requests"""
    try:
        # Get query parameters (case-insensitive)
        FilterData = request.args.to_dict()
        Currency = FilterData.get('Currency') or FilterData.get('currency')
        AcceptCurrency = FilterData.get('AcceptCurrency') or FilterData.get('acceptCurrency')
        Location = FilterData.get('Location') or FilterData.get('location')
        MaxDistance = FilterData.get('MaxDistance') or FilterData.get('maxDistance')
        UserLatitude = FilterData.get('UserLatitude') or FilterData.get('userLatitude')
        UserLongitude = FilterData.get('UserLongitude') or FilterData.get('userLongitude')
        MinAmount = FilterData.get('MinAmount') or FilterData.get('minAmount')
        MaxAmount = FilterData.get('MaxAmount') or FilterData.get('maxAmount')
        session_id = FilterData.get('session_id') or FilterData.get('session_id')
        Limit = FilterData.get('Limit') or FilterData.get('limit', 20)
        Offset = FilterData.get('Offset') or FilterData.get('offset', 0)
        
        # Call the search function
        result = search_listings(
            Currency=Currency,
            AcceptCurrency=AcceptCurrency,
            Location=Location,
            MaxDistance=MaxDistance,
            UserLatitude=UserLatitude,
            UserLongitude=UserLongitude,
            MinAmount=MinAmount,
            MaxAmount=MaxAmount,
            session_id=session_id,
            Limit=Limit,
            Offset=Offset
        )
        
        return result
        
    except Exception as e:
        return Debugger(e)

@search_bp.route('/Search/GetSearchFilters', methods=['GET'])
@cross_origin()
def GetSearchFilters():
    """Handle request for search filter options"""
    try:
        # Call the filters function
        result = get_search_filters()
        return result
        
    except Exception as e:
        return Debugger(e)

@search_bp.route('/Search/GetPopularSearches', methods=['GET'])
@cross_origin()
def GetPopularSearches():
    """Handle request for popular searches and trends"""
    try:
        # Call the popular searches function
        result = get_popular_searches()
        return result
        
    except Exception as e:
        return Debugger(e)
@search_bp.route('/Search/SearchListingsInRadius', methods=['GET'])
@cross_origin()
def SearchListingsInRadius():
    """Search for listings within a specific radius of a reference listing"""
    try:
        # Get query parameters
        FilterData = request.args.to_dict()
        session_id = FilterData.get('session_id') or FilterData.get('session_id')
        ListingId = FilterData.get('ListingId') or FilterData.get('listingId')
        SearchQuery = FilterData.get('SearchQuery') or FilterData.get('searchQuery') or ""
        Limit = FilterData.get('Limit') or FilterData.get('limit', 5)
        
        # Call the search function
        result = search_listings_in_radius(
            session_id=session_id,
            listing_id=ListingId,
            search_query=SearchQuery,
            limit=int(Limit)
        )
        
        return result
        
    except Exception as e:
        return Debugger(e)
