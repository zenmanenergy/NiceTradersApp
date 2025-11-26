import logging
from logging.handlers import RotatingFileHandler
import os
import sys
from flask import Flask, request

app = Flask(__name__)

# Setup logging
def setup_logging():
    try:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        log_dir = os.path.join(script_dir, 'logs')
        os.makedirs(log_dir, mode=0o755, exist_ok=True)
        
        file_handler = RotatingFileHandler(
            os.path.join(log_dir, 'test_app.log'),
            maxBytes=10485760,
            backupCount=10
        )
        file_handler.setLevel(logging.INFO)
        file_handler.setFormatter(logging.Formatter(
            '[%(asctime)s] %(levelname)s: %(message)s'
        ))
        
        error_handler = RotatingFileHandler(
            os.path.join(log_dir, 'test_error.log'),
            maxBytes=10485760,
            backupCount=10
        )
        error_handler.setLevel(logging.ERROR)
        error_handler.setFormatter(logging.Formatter(
            '[%(asctime)s] %(levelname)s [%(pathname)s:%(lineno)d]: %(message)s'
        ))
        
        app.logger.addHandler(file_handler)
        app.logger.addHandler(error_handler)
        app.logger.setLevel(logging.INFO)
        app.logger.info(f'File logging enabled: {log_dir}')
        return True
    except Exception as e:
        print(f'File logging disabled: {e}', file=sys.stderr)
        return False

setup_logging()

# Console logging
console_handler = logging.StreamHandler(sys.stderr)
console_handler.setLevel(logging.INFO)
console_handler.setFormatter(logging.Formatter('[%(asctime)s] %(message)s'))
app.logger.addHandler(console_handler)
app.logger.setLevel(logging.INFO)

app.logger.info('Test app starting...')

# Request/response logging
@app.before_request
def log_request():
    app.logger.info(f'Request: {request.method} {request.url}')

@app.after_request
def log_response(response):
    app.logger.info(f'Response: {response.status_code}')
    return response

# Error handlers
@app.errorhandler(Exception)
def handle_exception(e):
    app.logger.error(f'Unhandled exception: {e}', exc_info=True)
    return f"Error: {str(e)}", 500

@app.route("/")
def hello():
    app.logger.info('Hello route accessed')
    return "Hello World!"

@app.route("/test")
def test():
    app.logger.info('Test route accessed')
    return "Test route works!"

@app.route("/error")
def error():
    app.logger.info('Error route accessed - will trigger error')
    raise Exception("Test error for logging")

application = app
app.logger.info('Test app initialized')

if __name__ == "__main__":
    app.run(debug=True)
