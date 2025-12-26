from _Lib import Database
from _Lib.Debugger import Debugger
from flask import Blueprint, request
from flask_cors import CORS, cross_origin
from .GetProfile import get_profile
from .UpdateProfile import update_profile
from .UpdateSettings import update_settings
from .DeleteAccount import delete_account
from .UpdateDeviceToken import update_device_token
from flask_app import app

blueprint = Blueprint('Profile', __name__)

@blueprint.route("/Profile/GetProfile", methods=['GET'])
@cross_origin()
def GetProfile():
	try:
		ProfileData = request.args.to_dict()
		session_id = ProfileData.get('session_id', None)
		
		result = get_profile(session_id)
		return result
	except Exception as e:
		return Debugger(e)

@blueprint.route("/Profile/UpdateProfile", methods=['GET', 'POST'])
@cross_origin()
def UpdateProfile():
	try:
		# Support both GET and POST requests
		if request.method == 'POST':
			ProfileData = request.get_json() or {}
		else:
			ProfileData = request.args.to_dict()
		
		session_id = ProfileData.get('session_id', None)
		Name = ProfileData.get('name', None)
		Email = ProfileData.get('email', None)
		Phone = ProfileData.get('phone', None)
		Location = ProfileData.get('location', None)
		Bio = ProfileData.get('bio', None)
		PreferredLanguage = ProfileData.get('preferred_language', None)
		
		result = update_profile(session_id, Name, Email, Phone, Location, Bio, PreferredLanguage)
		return result
	except Exception as e:
		return Debugger(e)

@blueprint.route("/Profile/UpdateSettings", methods=['GET', 'POST'])
@cross_origin()
def UpdateSettings():
	try:
		SettingsData = request.args.to_dict()
		session_id = SettingsData.get('session_id', None)
		SettingsJson = SettingsData.get('settingsJson', None)
		
		result = update_settings(session_id, SettingsJson)
		return result
	except Exception as e:
		return Debugger(e)

@blueprint.route("/Profile/DeleteAccount", methods=['GET'])
@cross_origin()
def DeleteAccount():
	try:
		DeleteData = request.args.to_dict()
		session_id = DeleteData.get('session_id', None)
		
		result = delete_account(session_id)
		return result
	except Exception as e:
		return Debugger(e)

@blueprint.route("/Profile/UpdateDeviceToken", methods=['GET', 'POST'])
@cross_origin()
def UpdateDeviceTokenRoute():
	try:
		# Support both GET and POST requests
		if request.method == 'POST':
			TokenData = request.get_json() or {}
		else:
			TokenData = request.args.to_dict()
		
		user_id = TokenData.get('user_id', None)
		DeviceType = TokenData.get('deviceType', 'ios')
		DeviceToken = TokenData.get('deviceToken', None)
		AppVersion = TokenData.get('appVersion', None)
		OsVersion = TokenData.get('osVersion', None)
		
		result = update_device_token(user_id, DeviceType, DeviceToken, AppVersion, OsVersion)
		return result
	except Exception as e:
		return Debugger(e)