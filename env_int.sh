#!/bin/sh
#
# Script for setting the required environment variables in development.
# Adjust as required.
#
# Usage: source ./env.sh
#
# Author: Philip Sharland (philip.sharland@ons.gov.uk)
#
export RESPONSE_OPERATIONS_HTTP_PROTOCOL="http"
export RESPONSE_OPERATIONS_ACTIONEXPORTER_SERVICE_HOST="actionexportersvc-int.apps.devtest.onsclofo.uk"
export RESPONSE_OPERATIONS_ACTIONEXPORTER_SERVICE_PORT="80"
export RESPONSE_OPERATIONS_ACTION_SERVICE_HOST="actionsvc-int.apps.devtest.onsclofo.uk"
export RESPONSE_OPERATIONS_ACTION_SERVICE_PORT="80"
export RESPONSE_OPERATIONS_CASE_SERVICE_HOST="casesvc-int.apps.devtest.onsclofo.uk"
export RESPONSE_OPERATIONS_CASE_SERVICE_PORT="80"
export RESPONSE_OPERATIONS_PARTY_SERVICE_HOST="ras-party-service-int.apps.devtest.onsclofo.uk"
export RESPONSE_OPERATIONS_PARTY_SERVICE_PORT="80"
export RESPONSE_OPERATIONS_NOTIFYGATEWAY_SERVICE_HOST="notifygatewaysvc-int.apps.devtest.onsclofo.uk"
export RESPONSE_OPERATIONS_NOTIFYGATEWAY_SERVICE_PORT="80"
export RESPONSE_OPERATIONS_OAUTHSERVER_HOST="http://ras-django-int.apps.devtest.onsclofo.uk/api/v1/tokens"
