Response Operations Ruby Web Application
========================================

This Ruby Sinatra application demonstrates using Java web services to provide Region, LA, Caseload and associated Address and Questionnaire information.

Prerequisites
-------------

The application's `config.yml` configuration file references the Java web services using a `collect-server` name which needs to be present in your hosts file. It also references an LDAP server using an `ldap-server` name.

The application depends on the following RubyGems:

* [json](http://flori.github.io/json/)
* [net-ldap](https://github.com/ruby-ldap/ruby-net-ldap)
* [pg](https://bitbucket.org/ged/ruby-pg/wiki/Home)
* [rest-client](https://github.com/rest-client/rest-client)
* [rotp](https://github.com/mdp/rotp)
* [sass](https://github.com/sass/sass) (Not a runtime dependency; see below)
* [sinatra-content-for2](https://github.com/Undev/sinatra-content-for2)
* [sinatra-flash](https://github.com/SFEley/sinatra-flash)
* [sinatra-formkeeper](https://github.com/lyokato/sinatra-formkeeper)
* [will_paginate](https://github.com/mislav/will_paginate)

Running
-------

To run this project in development using its [Rackup](http://rack.github.io/) file use:

  `rackup config.ru -p 8179` (the `config.ru` may be omitted as Rack looks for this file by default)

and access using [http://localhost:8179](http://localhost:8179)

To daemonise the Rack process and use production mode, use:

  `rackup -D -E production -p 8179`

Running Using the Mock Backend
------------------------------

This project includes two Sinatra applications that provide mock versions of the FrameService and FollowUpService web services. To run them, edit your hosts file so that `collect-server` uses 127.0.0.1. Then run:

  `rackup -p 8178` from within the `mock\frameservice` directory and `rackup -p 8177` within the `mock\followupservice` directory. Alternatively, for an easy life, simply run `mock\run.cmd`.

Start the user interface normally as described above.

Compiling the Style Sheet using Sass
------------------------------------

This project uses the CSS preprocessor [Sass](http://sass-lang.com/) so that features such as variables and mixins that don't exist in pure CSS can be used. The SCSS syntax is used rather than the older Sass syntax. The application style sheet `public/screen.css` is compiled from the main Sass style sheet `views/stylesheets/screen.scss`, which in turn imports the other Sass style sheets in the same directory. To generate `screen.css` from `screen.scss` use:

 `sass -t compressed screen.scss ../../../public/css/screen.css`

 from within the `views/stylesheets` directory. Omit `-t compressed` for non-minified CSS output.
