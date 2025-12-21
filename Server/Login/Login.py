
from _Lib import Database
from _Lib.Debugger import Debugger
from flask import Blueprint, request
from flask_cors import CORS, cross_origin
from .GetLogin import get_login
from .VerifySession import verify_session
from .ForgotPassword import forgot_password, reset_password

blueprint = Blueprint('Login', __name__)

@blueprint.route("/Login/Login", methods=['GET'])
@cross_origin()
def Login():
	try:
		from Profile.RegisterDevice import log_device_event
		LoginData = request.args.to_dict()
		log_device_event(f"LOGIN ENDPOINT HIT: LoginData={LoginData}")

		# Extract the Email and Password from the LoginData
		Email = LoginData.get('Email', None)
		Password = LoginData.get('Password', None)
		
		# Extract optional device information
		device_token = LoginData.get('deviceToken', None)
		device_type = LoginData.get('deviceType', 'ios')
		device_name = LoginData.get('deviceName', None)
		app_version = LoginData.get('appVersion', None)
		os_version = LoginData.get('osVersion', None)
		
		log_device_event(f"LOGIN EXTRACTED: Email={Email}, device_token={device_token}, device_type={device_type}, device_name={device_name}, app_version={app_version}, os_version={os_version}")

		# Call the get_login function from GetLogin.py with the extracted data
		result = get_login(Email, Password, device_token, device_type, device_name, app_version, os_version)
		log_device_event(f"LOGIN RESULT: {result}")

		return result
	except Exception as e:
		
		return Debugger(e)
		
@blueprint.route("/Login/Verify", methods=['GET'])
@cross_origin()
def Verify():
	try:
		VerifyData = request.args.to_dict()

		# Extract the Email and Password from the LoginData
		SessionId = VerifyData.get('SessionId', None)

		# Call the get_login function from GetLogin.py with the extracted data
		result = verify_session(SessionId)

		return result
	except Exception as e:
		
		return Debugger(e)

@blueprint.route("/Login/ForgotPassword", methods=['POST', 'GET'])
@cross_origin()
def ForgotPassword():
	try:
		# Handle both GET and POST requests
		if request.method == 'GET':
			data = request.args.to_dict()
		else:
			data = request.get_json()
		
		email = data.get('email', None)
		
		if not email:
			return {'success': False, 'error': 'Email is required'}
		
		result = forgot_password(email)
		return result
	except Exception as e:
		return Debugger(e)

@blueprint.route("/Login/ResetPassword", methods=['POST'])
@cross_origin()
def ResetPassword():
	try:
		data = request.get_json()
		
		reset_token = data.get('resetToken', None)
		new_password = data.get('newPassword', None)
		
		if not reset_token or not new_password:
			return {'success': False, 'error': 'Reset token and new password are required'}
		
		if len(new_password) < 6:
			return {'success': False, 'error': 'Password must be at least 6 characters'}
		
		result = reset_password(reset_token, new_password)
		return result
	except Exception as e:
		return Debugger(e)
