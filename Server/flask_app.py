
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
from Negotiations.Negotiations import negotiations_bp

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

@app.route("/")
@cross_origin()
def index():
	return "it works"

application=app