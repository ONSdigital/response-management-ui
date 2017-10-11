#!/bin/sh
#
# Script for setting the required environment variables in development.
# Adjust as required.
#
# Usage: . ./env_local.sh
#
# Author: Philip Sharland (philip.sharland@ons.gov.uk)
#
if [ "$#" -eq 4 ]; then
  export BRES_2017_COLLECTION_EXERCISE="14fb3e68-4dca-46db-bf49-04b84e07e77c"
  export RAS_BACKSTAGE_UI_COLLECTION_EXERCISES="collection-exercises"
  export RAS_BACKSTAGE_UI_PROTOCOL="http"
  export RAS_BACKSTAGE_UI_HOST="ras-backstage-dev.apps.devtest.onsclofo.uk"
  export RESPONSE_OPERATIONS_ACTION_SERVICE_HOST="localhost"
  export RESPONSE_OPERATIONS_ACTION_SERVICE_PORT="8151"
  export RESPONSE_OPERATIONS_SURVEY_SERVICE_HOST="localhost"
  export RESPONSE_OPERATIONS_SURVEY_SERVICE_PORT="8080"
  export RESPONSE_OPERATIONS_ACTIONEXPORTER_SERVICE_HOST="localhost"
  export RESPONSE_OPERATIONS_ACTIONEXPORTER_SERVICE_PORT="8141"
  export RESPONSE_OPERATIONS_CASE_SERVICE_HOST="localhost"
  export RESPONSE_OPERATIONS_CASE_SERVICE_PORT="8171"
  export RESPONSE_OPERATIONS_SAMPLE_SERVICE_HOST="localhost"
  export RESPONSE_OPERATIONS_SAMPLE_SERVICE_PORT="8151"
  export RESPONSE_OPERATIONS_COLLECTION_EXERCISE_SERVICE_HOST="localhost"
  export RESPONSE_OPERATIONS_COLLECTION_EXERCISE_SERVICE_PORT="8145"
  export RESPONSE_OPERATIONS_HTTP_PROTOCOL="http"
  export RESPONSE_OPERATIONS_OAUTHSERVER_HOST="http://ras-django-dev.apps.devtest.onsclofo.uk/api/v1/tokens"
  export RESPONSE_OPERATIONS_PARTY_SERVICE_HOST="localhost"
  export RESPONSE_OPERATIONS_PARTY_SERVICE_PORT="5062"
  export RESPONSE_OPERATIONS_SECURE_MESSAGE_SERVICE_HOST="ras-backstage-dev.apps.devtest.onsclofo.uk/secure-messages"
  export RESPONSE_OPERATIONS_SECURE_MESSAGE_SERVICE_PORT="80"
  export RESPONSE_OPERATIONS_CLIENT_USER=$1
  export RESPONSE_OPERATIONS_CLIENT_PASSWORD=$2
  export security_user_name=$3
  export security_user_password=$4
else
  echo "Usage: env.sh [RESPONSE_OPERATIONS_CLIENT_USER] [RESPONSE_OPERATIONS_CLIENT_PASSWORD] [security_user_name] [security_user_password]"
fi
