#!/bin/sh
#
# Script for setting the required environment variables in integration.
# Adjust as required.
#
# Usage: . ./env_int.sh
#
# Author: Philip Sharland (philip.sharland@ons.gov.uk)
#
if [ "$#" -eq 5 ]; then
  export BRES_2017_COLLECTION_EXERCISE="14fb3e68-4dca-46db-bf49-04b84e07e77c"
  export RAS_BACKSTAGE_UI_COLLECTION_EXERCISES="collection-exercises"
  export RAS_BACKSTAGE_UI_PROTOCOL="http"
  export RAS_BACKSTAGE_UI_HOST="ras-backstage-$1.apps.devtest.onsclofo.uk"
  export RESPONSE_OPERATIONS_ACTION_SERVICE_HOST="actionsvc-$1.apps.devtest.onsclofo.uk"
  export RESPONSE_OPERATIONS_ACTION_SERVICE_PORT="80"
  export RESPONSE_OPERATIONS_SURVEY_SERVICE_HOST="surveysvc-$1.apps.devtest.onsclofo.uk"
  export RESPONSE_OPERATIONS_SURVEY_SERVICE_PORT="80"
  export RESPONSE_OPERATIONS_ACTIONEXPORTER_SERVICE_HOST="actionexportersvc-$1.apps.devtest.onsclofo.uk"
  export RESPONSE_OPERATIONS_ACTIONEXPORTER_SERVICE_PORT="80"
  export RESPONSE_OPERATIONS_CASE_SERVICE_HOST="casesvc-$1.apps.devtest.onsclofo.uk"
  export RESPONSE_OPERATIONS_CASE_SERVICE_PORT="80"
  export RESPONSE_OPERATIONS_SAMPLE_SERVICE_HOST="samplesvc-$1.apps.devtest.onsclofo.uk"
  export RESPONSE_OPERATIONS_SAMPLE_SERVICE_PORT="80"
  export RESPONSE_OPERATIONS_COLLECTION_EXERCISE_SERVICE_HOST="collectionexercisesvc-$1.apps.devtest.onsclofo.uk"
  export RESPONSE_OPERATIONS_COLLECTION_EXERCISE_SERVICE_PORT="80"
  export RESPONSE_OPERATIONS_HTTP_PROTOCOL="http"
  export RESPONSE_OPERATIONS_OAUTHSERVER_HOST="http://ras-django-$1.apps.devtest.onsclofo.uk/api/v1/tokens"
  export RESPONSE_OPERATIONS_PARTY_SERVICE_HOST="ras-party-service-$1.apps.devtest.onsclofo.uk"
  export RESPONSE_OPERATIONS_PARTY_SERVICE_PORT="80"
  export RESPONSE_OPERATIONS_SECURE_MESSAGE_SERVICE_HOST="ras-backstage-$1.apps.devtest.onsclofo.uk/secure-messages"
  export RESPONSE_OPERATIONS_SECURE_MESSAGE_SERVICE_PORT="80"
  export RESPONSE_OPERATIONS_CLIENT_USER=$2
  export RESPONSE_OPERATIONS_CLIENT_PASSWORD=$3
  export security_user_name=$4
  export security_user_password=$5
else
  echo "Usage: env.sh [environment] [RESPONSE_OPERATIONS_CLIENT_USER] [RESPONSE_OPERATIONS_CLIENT_PASSWORD] [security_user_name] [security_user_password]"
fi
