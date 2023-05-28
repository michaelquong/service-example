#!/bin/sh
set -e

FLASK_ENV="${FLASK_ENV:-development}"
FLASK="flask --app app.py"
GUNICORN=gunicorn
PORT="${FLASK_PORT:-5000}"

# Apply migrations
  echo "applying database upgrades"
  $FLASK db upgrade

if [ "$FLASK_ENV" = "development" ]; then
  echo "Running in development mode"
  # Perform actions specific to development environment
  # For example, start a development server in debug
  
  exec $FLASK run --host "0.0.0.0" "$@"

elif [ "$FLASK_ENV" = "production" ]; then
  echo "Running in production mode"
  # Perform actions specific to production environment
  # For example, start the production server using Gunicorn
  
  exec $GUNICORN --bind :$PORT app:app "$@"
else
  echo "FLASK_ENV is not set to development or production"
fi