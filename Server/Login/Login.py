
from _Lib import Database
from _Lib.Debugger import Debugger
from flask import Blueprint, request
from flask_cors import CORS, cross_origin
from .GetLogin import get_login
from .VerifySession import verify_session
from flask_app import app

blueprint = Blueprint('Login', __name__)

@blueprint.route("/Login/Login", methods=['GET'])
@cross_origin()
def Login():
	try:
		LoginData = request.args.to_dict()

		# Extract the Email and Password from the LoginData
		Email = LoginData.get('Email', None)
		Password = LoginData.get('Password', None)

		# Call the get_login function from GetLogin.py with the extracted data
		result = get_login(Email, Password)

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