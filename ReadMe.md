Response Operations Ruby Web Application
========================================

This Ruby [Sinatra](http://www.sinatrarb.com/) application is the user interface for the Response Management product. It enables cases to be managed and located via a postcode search. It consumes the Action and Case web services and interfaces with an OpenLDAP server to provide authentication.

Prerequisites
-------------

The application's `config.yml` configuration file references the Java web services using a `collect-server` name that needs to be present in your hosts file. It also references an LDAP server using an `ldap-server` name. Install the RubyGems the application depends on by running `bundle install`.

Running
-------

To run this project in development using its [Rackup](http://rack.github.io/) file use:

  `bundle exec rackup config.ru` (the `config.ru` may be omitted as Rack looks for this file by default)

and access using [http://localhost:9292](http://localhost:9292)

Running Using the Mock Backend
------------------------------

This project includes two Sinatra applications that provide mock versions of the Action and Case web services. To run them, edit your hosts file so that `collect-server` uses 127.0.0.1. Then run:

  `./run.sh` from within the `mock` directory. This is a shell script that starts both mock web services in the background. Use Ctrl + C to terminate them. The output from the background processes is written to `mock/nohup.out`. This file can be deleted if not required.

Start the user interface normally as described above.

Compiling the Style Sheet using Sass
------------------------------------

This project uses the CSS preprocessor [Sass](http://sass-lang.com/) so that features such as variables and mixins that don't exist in pure CSS can be used. The SCSS syntax is used rather than the older Sass syntax. The application style sheet `public/screen.css` is compiled from the main Sass style sheet `views/stylesheets/screen.scss`, which in turn imports the other Sass style sheets in the same directory. To generate `screen.css` from `screen.scss` use:

 `sass -t compressed screen.scss ../../../public/css/screen.css`

 from within the `views/stylesheets` directory. Omit `-t compressed` for non-minified CSS output.
