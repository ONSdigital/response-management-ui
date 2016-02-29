Response Operations Ruby Web Application
========================================

This Ruby Sinatra application demonstrates using Java web services to provide Region, LA, Caseload and associated Address and Questionnaire information.

Prerequisites
-------------

The application's `config.yml` configuration file references the Java web services using a `collect-server` name which needs to be present in your hosts file. It also references an LDAP server using an `ldap-server` name. Install the RubyGems the applications depends on by running `bundle install`.

Running
-------

To run this project in development using its [Rackup](http://rack.github.io/) file use:

  `bundle exec rackup config.ru` (the `config.ru` may be omitted as Rack looks for this file by default)

and access using [http://localhost:9292](http://localhost:9292)

Running Using the Mock Backend
------------------------------

This project includes two Sinatra applications that provide mock versions of the FrameService and FollowUpService web services. To run them, edit your hosts file so that `collect-server` uses 127.0.0.1. Then run:

  `bundle exec rackup -p 8178` from within the `mock\frameservice` directory and `bundle exec rackup -p 8177` within the `mock\followupservice` directory.

Start the user interface normally as described above.

Compiling the Style Sheet using Sass
------------------------------------

This project uses the CSS preprocessor [Sass](http://sass-lang.com/) so that features such as variables and mixins that don't exist in pure CSS can be used. The SCSS syntax is used rather than the older Sass syntax. The application style sheet `public/screen.css` is compiled from the main Sass style sheet `views/stylesheets/screen.scss`, which in turn imports the other Sass style sheets in the same directory. To generate `screen.css` from `screen.scss` use:

 `sass -t compressed screen.scss ../../../public/css/screen.css`

 from within the `views/stylesheets` directory. Omit `-t compressed` for non-minified CSS output.
