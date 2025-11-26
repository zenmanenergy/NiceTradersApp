
from flask import Flask, request
from flask_cors import CORS, cross_origin

app = Flask(__name__)
cors = CORS(app)
app.config['CORS_HEADERS'] = 'Content-Type'
app.debug = True

from Login import Login
from Signup import Signup
from Profile import Profile
from Listings import Listings
from Dashboard import Dashboard
from Search import Search
from Contact import Contact
from ExchangeRates import ExchangeRates
from Meeting import Meeting
from Admin import Admin
from Translations import Translations, AdminTranslations

app.register_blueprint(Login.blueprint)
app.register_blueprint(Signup.blueprint)
app.register_blueprint(Profile.blueprint)
app.register_blueprint(Listings.blueprint)
app.register_blueprint(Dashboard.dashboard_bp)
app.register_blueprint(Search.search_bp)
app.register_blueprint(Contact.contact_bp)
app.register_blueprint(ExchangeRates.exchange_rates_bp)
app.register_blueprint(Meeting.blueprint)
app.register_blueprint(Admin.blueprint)
app.register_blueprint(Translations.translations_bp)
app.register_blueprint(AdminTranslations.admin_translations_bp)

app.logger.info('All blueprints registered successfully')

# Request logging middleware
@app.before_request
def log_request_info():
    app.logger.info(f'Request: {request.method} {request.url}')
    if request.method in ['POST', 'PUT', 'PATCH']:
        app.logger.info(f'Request data: {request.get_data(as_text=True)[:500]}')  # Log first 500 chars

@app.after_request
def log_response_info(response):
    app.logger.info(f'Response: {response.status_code} for {request.method} {request.url}')
    return response

# Error handlers
@app.errorhandler(404)
def not_found_error(error):
    app.logger.error(f'404 Not Found: {request.url}')
    return "Not Found", 404

@app.errorhandler(500)
def internal_error(error):
    app.logger.error(f'500 Internal Server Error: {error}', exc_info=True)
    return "Internal Server Error", 500

@app.errorhandler(Exception)
def handle_exception(e):
    app.logger.error(f'Unhandled exception: {e}', exc_info=True)
    return "An error occurred", 500

@app.route("/")
@cross_origin()
def index():
	app.logger.info('Index route accessed')
	return "it works"

@app.route("/diagnostic/logging")
@cross_origin()
def diagnostic_logging():
	"""Diagnostic endpoint to check logging configuration"""
	import sys
	output = []
	output.append("=" * 60)
	output.append("LOGGING DIAGNOSTIC")
	output.append("=" * 60)
	
	# Basic info
	output.append(f"\nPython Version: {sys.version}")
	output.append(f"Current Working Directory: {os.getcwd()}")
	output.append(f"Script File: {__file__}")
	output.append(f"Script Directory: {os.path.dirname(os.path.abspath(__file__))}")
	
	# Check __main__
	if hasattr(sys.modules['__main__'], '__file__'):
		output.append(f"Main File: {os.path.abspath(sys.modules['__main__'].__file__)}")
	else:
		output.append("WARNING: __main__ has no __file__ attribute")
	
	# Check log handlers
	output.append(f"\nApp Logger Handlers: {len(app.logger.handlers)}")
	for i, handler in enumerate(app.logger.handlers):
		output.append(f"  Handler {i}: {type(handler).__name__}")
		if hasattr(handler, 'baseFilename'):
			output.append(f"    File: {handler.baseFilename}")
			output.append(f"    Exists: {os.path.exists(handler.baseFilename)}")
			if os.path.exists(handler.baseFilename):
				output.append(f"    Size: {os.path.getsize(handler.baseFilename)} bytes")
	
	# Try to write a test log
	try:
		app.logger.info("TEST LOG FROM DIAGNOSTIC ENDPOINT")
		output.append("\n✓ Successfully wrote test log entry")
	except Exception as e:
		output.append(f"\n✗ Failed to write test log: {e}")
	
	# Test directory creation
	test_dirs = [
		os.path.join(os.getcwd(), 'logs'),
		os.path.join(os.path.dirname(os.path.abspath(__file__)), 'logs'),
		'/tmp/flask_logs'
	]
	
	output.append("\nTesting log directories:")
	for test_dir in test_dirs:
		output.append(f"\n  {test_dir}")
		output.append(f"    Exists: {os.path.exists(test_dir)}")
		output.append(f"    Writable: {os.access(test_dir, os.W_OK) if os.path.exists(test_dir) else 'N/A'}")
		
		# Try to write a test file
		try:
			test_file = os.path.join(test_dir, 'diagnostic_test.txt')
			with open(test_file, 'w') as f:
				f.write('test')
			os.remove(test_file)
			output.append(f"    Write Test: ✓")
		except Exception as e:
			output.append(f"    Write Test: ✗ {e}")
	
	# Environment
	output.append("\nEnvironment Variables:")
	for var in ['HOME', 'USER', 'PWD', 'FLASK_APP']:
		output.append(f"  {var}: {os.environ.get(var, 'Not set')}")
	
	output.append("\n" + "=" * 60)
	
	return "<pre>" + "\n".join(output) + "</pre>"

application=app
app.logger.info('Flask application initialized successfully')