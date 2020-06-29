#!/usr/bin/env bash

set -e

echo "Starting $RAILS_ENV"

if [ "$RAILS_ENV" = "test" ] || [ "$RAILS_ENV" = "development" ]
then
  DATABASE_SERVICE=tcp://incomeapi-db:3306
  echo "Waiting for database to come up on $DATABASE_SERVICE"
  # Wait for database to come up
  dockerize -wait "$DATABASE_SERVICE" -timeout 1m

  # Setup the database - safe if it is already configured

  if [ "$RAILS_ENV" = "development" ]
  then
    rails db:environment:set RAILS_ENV=development
  fi

  rails db:setup
fi

# Start app
exec "$@"
