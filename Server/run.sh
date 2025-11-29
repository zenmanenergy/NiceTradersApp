#!/bin/bash

# Activate virtual environment
source ../.venv/bin/activate

# Run Flask app
flask --app flask_app run --host=0.0.0.0 --port=9000 --reload
