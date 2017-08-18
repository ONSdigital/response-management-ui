#!/bin/sh
#
# Script for setting the required environment variables in integration.
# Adjust as required.
#
# Usage: . ./env_int.sh
#
# Author: Philip Sharland (philip.sharland@ons.gov.uk)
#
export BRES_2017_COLLECTION_EXERCISE="14fb3e68-4dca-46db-bf49-04b84e07e77c"
export RAS_BACKSTAGE_UI_COLLECTION_EXERCISES="collection-exercises"
export RAS_BACKSTAGE_UI_HTTP_PROTOCOL="http"
export RAS_BACKSTAGE_UI_HOST="ras-backstage-int.apps.devtest.onsclofo.uk"
export RESPONSE_OPERATIONS_ACTION_SERVICE_HOST="actionsvc-int.apps.devtest.onsclofo.uk"
export RESPONSE_OPERATIONS_ACTION_SERVICE_PORT="80"
export RESPONSE_OPERATIONS_ACTIONEXPORTER_SERVICE_HOST="actionexportersvc-int.apps.devtest.onsclofo.uk"
export RESPONSE_OPERATIONS_ACTIONEXPORTER_SERVICE_PORT="80"
export RESPONSE_OPERATIONS_CASE_SERVICE_HOST="casesvc-int.apps.devtest.onsclofo.uk"
export RESPONSE_OPERATIONS_CASE_SERVICE_PORT="80"
export RESPONSE_OPERATIONS_COLLECTION_EXERCISE_SERVICE_HOST="collectionexercisesvc-int.apps.devtest.onsclofo.uk"
export RESPONSE_OPERATIONS_COLLECTION_EXERCISE_SERVICE_PORT="80"
export RESPONSE_OPERATIONS_EMAIL_TEMPLATE_ID="53c59576-8c3b-4298-99d1-b245ddd28500"
export RESPONSE_OPERATIONS_HTTP_PROTOCOL="http"
export RESPONSE_OPERATIONS_NOTIFYGATEWAY_SERVICE_HOST="notifygatewaysvc-int.apps.devtest.onsclofo.uk"
export RESPONSE_OPERATIONS_NOTIFYGATEWAY_SERVICE_PORT="80"
export RESPONSE_OPERATIONS_OAUTHSERVER_HOST="http://ras-django-int.apps.devtest.onsclofo.uk/api/v1/tokens"
export RESPONSE_OPERATIONS_PARTY_SERVICE_HOST="ras-party-service-int.apps.devtest.onsclofo.uk"
export RESPONSE_OPERATIONS_PARTY_SERVICE_PORT="80"
export RESPONSE_OPERATIONS_SECURE_MESSAGE_SERVICE_HOST="ras-backstage-int.apps.devtest.onsclofo.uk/secure-messages/create-message"
export RESPONSE_OPERATIONS_SECURE_MESSAGE_SERVICE_PORT="80"
