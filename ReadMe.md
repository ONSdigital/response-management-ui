[![Codacy Badge](https://api.codacy.com/project/badge/Grade/ab8e513f5e8d48ec8ac8afd945293f8a)](https://www.codacy.com/app/sdcplatform/response-management-ui?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=ONSdigital/response-management-ui&amp;utm_campaign=Badge_Grade)  [![Docker Pulls](https://img.shields.io/docker/pulls/sdcplatform/response-management-ui.svg)]()

# Response Management User Interface
Response Management is part of ONS's Survey Data Collection platform. It covers overall management of the survey (across all survey modes). It manages the survey sample, tracks responses and initiates required follow-up actions during the collection period.

This Ruby [Sinatra](http://www.sinatrarb.com/) application is the back office user interface for Response Management. It enables cases to be managed and located via a postcode search. It consumes the [Action and Case web services](https://github.com/ONSdigital/response-management-service) and interfaces with an OpenLDAP server to provide authentication.

## Prerequisites
The application's `config.yml` configuration file references the Java web services using a `collect-server` name that needs to be present in your hosts file. It also references an LDAP server using an `ldap-server` name. Install the RubyGems the application depends on by running `bundle install`.

## Running
To run this project in development using its [Rackup](http://rack.github.io/) file use:

  `bundle exec rackup config.ru` (the `config.ru` may be omitted as Rack looks for this file by default)

and access using [http://localhost:9292](http://localhost:9292)

## Environment Variables
The environment variables below must be provided:

```
BRES_2017_COLLECTION_EXERCISE
RAS_BACKSTAGE_UI_COLLECTION_EXERCISES
RAS_BACKSTAGE_UI_HOST
RAS_BACKSTAGE_UI_PROTOCOL
RESPONSE_OPERATIONS_ACTION_SERVICE_HOST
RESPONSE_OPERATIONS_ACTION_SERVICE_PORT
RESPONSE_OPERATIONS_ACTIONEXPORTER_SERVICE_HOST
RESPONSE_OPERATIONS_ACTIONEXPORTER_SERVICE_PORT
RESPONSE_OPERATIONS_CASE_SERVICE_HOST
RESPONSE_OPERATIONS_CASE_SERVICE_PORT
RESPONSE_OPERATIONS_COLLECTION_EXERCISE_SERVICE_HOST
RESPONSE_OPERATIONS_COLLECTION_EXERCISE_SERVICE_PORT
RESPONSE_OPERATIONS_EMAIL_TEMPLATE_ID
RESPONSE_OPERATIONS_HTTP_PROTOCOL
RESPONSE_OPERATIONS_NOTIFYGATEWAY_SERVICE_HOST
RESPONSE_OPERATIONS_NOTIFYGATEWAY_SERVICE_PORT
RESPONSE_OPERATIONS_OAUTHSERVER_HOST
RESPONSE_OPERATIONS_PARTY_SERVICE_HOST
RESPONSE_OPERATIONS_PARTY_SERVICE_PORT
RESPONSE_OPERATIONS_SECURE_MESSAGE_SERVICE_HOST
RESPONSE_OPERATIONS_SECURE_MESSAGE_SERVICE_PORT
```

The script `/env_<cf env>.sh` can be sourced in development to set these variables with reasonable defaults.

There are two additional environment variables required `RESPONSE_OPERATIONS_CLIENT_USER` and `RESPONSE_OPERATIONS_CLIENT_PASSWORD`, the values for these are found in the wiki page for deploying to Cloud Foundry:

```
export RESPONSE_OPERATIONS_CLIENT_USER=
export RESPONSE_OPERATIONS_CLIENT_PASSWORD=
```

## Compiling the Style Sheet using Sass
This project uses the CSS preprocessor [Sass](http://sass-lang.com/) so that features such as variables and mixins that don't exist in pure CSS can be used. The SCSS syntax is used rather than the older Sass syntax. The application style sheet `public/screen.css` is compiled from the main Sass style sheet `views/stylesheets/screen.scss`, which in turn imports the other Sass style sheets in the same directory. To generate `screen.css` from `screen.scss` use:

 `sass -t compressed screen.scss ../../public/css/screen.css`

 from within the `views/stylesheets` directory. Omit `-t compressed` for non-minified CSS output.

## Authentication

The Response Operations UI is authenticated against oauth.

The Django administration page will need to be logged into and Client Identifiers/users will need to be added

```
http://ras-django-<cf environment>.apps.devtest.onsclofo.uk/admin
```

Credentials can be obtained from RAS colleagues in Newport.

## Copyright
Copyright (C) 2016 Crown Copyright (Office for National Statistics)
