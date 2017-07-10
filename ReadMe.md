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

## Running Using the Mock Backend
This project includes two Sinatra applications that provide mock versions of the Action and Case web services. To run them, edit your hosts file so that `collect-server` uses 127.0.0.1. Then run:

  `./run.sh` from within the `mock` directory. This is a shell script that starts both mock web services in the background. Use Ctrl + C to terminate them. The output from the background processes is written to `mock/nohup.out`. This file can be deleted if not required.

Start the user interface normally as described above.

## Compiling the Style Sheet using Sass
This project uses the CSS preprocessor [Sass](http://sass-lang.com/) so that features such as variables and mixins that don't exist in pure CSS can be used. The SCSS syntax is used rather than the older Sass syntax. The application style sheet `public/screen.css` is compiled from the main Sass style sheet `views/stylesheets/screen.scss`, which in turn imports the other Sass style sheets in the same directory. To generate `screen.css` from `screen.scss` use:

 `sass -t compressed screen.scss ../../public/css/screen.css`

 from within the `views/stylesheets` directory. Omit `-t compressed` for non-minified CSS output.

## Copyright
Copyright (C) 2016 Crown Copyright (Office for National Statistics)
