#!/bin/sh
#
# Script for setting the required environment variables in development.
# Adjust as required.
#
# Usage: . ./env_dev.sh
#
# Author: Philip Sharland (philip.sharland@ons.gov.uk)
#
export RESPONSE_OPERATIONS_HTTP_PROTOCOL="http"
export RESPONSE_OPERATIONS_ACTIONEXPORTER_SERVICE_HOST="actionexportersvc-dev.apps.devtest.onsclofo.uk"
export RESPONSE_OPERATIONS_ACTIONEXPORTER_SERVICE_PORT="80"
export RESPONSE_OPERATIONS_ACTION_SERVICE_HOST="actionsvc-dev.apps.devtest.onsclofo.uk"
export RESPONSE_OPERATIONS_ACTION_SERVICE_PORT="80"
export RESPONSE_OPERATIONS_CASE_SERVICE_HOST="casesvc-dev.apps.devtest.onsclofo.uk"
export RESPONSE_OPERATIONS_CASE_SERVICE_PORT="80"
export RESPONSE_OPERATIONS_PARTY_SERVICE_HOST="ras-party-service-dev.apps.devtest.onsclofo.uk"
export RESPONSE_OPERATIONS_PARTY_SERVICE_PORT="80"
export RESPONSE_OPERATIONS_COLLECTION_EXERCISE_SERVICE_HOST="collectionexercisesvc-dev.apps.devtest.onsclofo.uk"
export RESPONSE_OPERATIONS_COLLECTION_EXERCISE_SERVICE_PORT="80"
export RESPONSE_OPERATIONS_NOTIFYGATEWAY_SERVICE_HOST="notifygatewaysvc-dev.apps.devtest.onsclofo.uk"
export RESPONSE_OPERATIONS_NOTIFYGATEWAY_SERVICE_PORT="80"
export RESPONSE_OPERATIONS_OAUTHSERVER_HOST="http://ras-django-dev.apps.devtest.onsclofo.uk/api/v1/tokens"
