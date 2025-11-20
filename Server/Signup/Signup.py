from _Lib import Database
from _Lib.Debugger import Debugger
from flask import Blueprint, request
from flask_cors import CORS, cross_origin
from .CreateAccount import create_account
from .CheckEmailExists import check_email_exists
from flask_app import app

blueprint = Blueprint('Signup', __name__)

@blueprint.route("/Signup/CreateAccount", methods=['GET'])
@cross_origin()
def CreateAccount():
	try:
		SignupData = request.args.to_dict()

		# Extract the signup data
		FirstName = SignupData.get('firstName', None)
		LastName = SignupData.get('lastName', None)
		Email = SignupData.get('email', None)
		Phone = SignupData.get('phone', None)
		Password = SignupData.get('password', None)

		# Call the create_account function with the extracted data
		result = create_account(FirstName, LastName, Email, Phone, Password)

		return result
	except Exception as e:
		return Debugger(e)

@blueprint.route("/Signup/CheckEmail", methods=['GET'])
@cross_origin()
def CheckEmail():
	try:
		Email = request.args.get('email', None)
		
		# Call the check_email_exists function
		result = check_email_exists(Email)
		
		return result
	except Exception as e:
		return Debugger(e)