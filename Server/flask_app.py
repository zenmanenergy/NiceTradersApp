
from flask import Flask, request
from flask_cors import CORS, cross_origin
import logging
import sys
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

app = Flask(__name__)
cors = CORS(app)
app.config['CORS_HEADERS'] = 'Content-Type'
app.debug = True

# PayPal Configuration
app.config['PAYPAL_CLIENT_ID'] = os.getenv('PAYPAL_CLIENT_ID', '')
app.config['PAYPAL_CLIENT_SECRET'] = os.getenv('PAYPAL_CLIENT_SECRET', '')
app.config['PAYPAL_MODE'] = os.getenv('PAYPAL_MODE', 'sandbox')

# Enable logging to stdout/stderr
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    stream=sys.stdout
)

# Force print to flush immediately
import functools
print = functools.partial(print, flush=True)

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
from Negotiations.Negotiations import negotiations_bp
from Ratings import ratings_bp
from Payments import Payments

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
app.register_blueprint(negotiations_bp)
app.register_blueprint(ratings_bp)
app.register_blueprint(Payments.payments_bp)

@app.route("/")
@cross_origin()
def index():
	return "it works"

application=app