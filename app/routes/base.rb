require 'sinatra/content_for2'
require 'sinatra/flash'
require 'sinatra/formkeeper'
require 'will_paginate'
require 'will_paginate/array'
require 'rest_client'
require 'ons-ldap'
require 'json'
require 'yaml'

require_relative '../lib/authentication'
require_relative '../models/user'

module Beyond
  module Routes
    NO_2FA_COOKIE = 'response_operations_no_2fa'
    CLOCK_DRIFT   = 120
    SIX_HOURS     = 60 * 60 * 6
    THIRTY_DAYS   = 60 * 60 * 24 * 30

    class Base < Sinatra::Application
      configure do

        # Load various settings from a configuration file.
        config = YAML.load_file(File.join(__dir__, '../../config/config.yml'))
        set :frame_service_host, config['frame-webservice']['host']
        set :frame_service_port, config['frame-webservice']['port']
        set :action_service_host, config['action-webservice']['host']
        set :action_service_port, config['action-webservice']['port']
        set :follow_up_service_host, config['follow-up-webservice']['host']
        set :follow_up_service_port, config['follow-up-webservice']['port']
        set :ldap_directory_host, config['ldap-directory']['host']
        set :ldap_directory_port, config['ldap-directory']['port']
        set :ldap_directory_base, config['ldap-directory']['base']
        set :ldap_groups, config['ldap-directory']['groups']
        set :google_maps_api_key, config['google-maps']['api-key']
        set :helpline_mi_directory, config['helpline-mi']['directory']

        # Display badges with the built date, environment and commit SHA on the
        # Sign In screen in non-production environments.
        set :built, config['badges']['built']
        set :commit, config['badges']['commit']
        set :environment, config['badges']['environment']

        # Expire sessions after ten minutes of inactivity.
        use Rack::Session::Cookie, key: 'rack.session', path: '/',
                                   secret: 'eb46fa947d8411e5996329c9ef0ba35d',
                                   expire_after: SIX_HOURS

        # Set global view options.
        set :erb, escape_html: false
        set :views, File.dirname(__FILE__) + '/../views'
        set :public_folder, File.dirname(__FILE__) + '/../../public'

        # Set global pagination options.
        WillPaginate.per_page = 20
      end

      # View helper for defining blocks inside views for rendering in templates.
      helpers Sinatra::ContentFor2
      helpers Authentication
      helpers do

        # Follow-up helpers.
        def active(follow_up)
          follow_up['status'].downcase == 'active'
        end

        def cancelling(follow_up)
          follow_up['status'].downcase == 'cancelling'
        end

        # View helper for escaping HTML output.
        def h(text)
          Rack::Utils.escape_html(text)
        end
      end

      # Always send UTF-8 Content-Type HTTP header.
      before do
        headers 'Content-Type' => 'text/html; charset=utf-8'
      end

      # Only administrators and escalation team can access the management screens.
      before '/manage*' do
        halt 403 unless authorised?('collect-admins') || authorised?('collect-escalate')
      end

      # Only administrators can access the admin screens.
      before '/admin*' do
        halt 403 unless authorised?('collect-admins')
      end

      # Error pages.
      error 403 do
        erb :forbidden, locals: { title: '403 Forbidden' }
      end

      error 404 do
        erb :not_found, locals: { title: '404 Not Found' }
      end

      error 500 do
        erb :internal_server_error, locals: { title: '500 Internal Server Error' }
      end

      # Home page.
      get '/' do
        authenticate!
        erb :index, locals: { title: 'Home' }
      end

      get '/signin/?' do

        # CTPA-404 Always bypass the two factor authentication screen for 2016.
        response.set_cookie(NO_2FA_COOKIE, value: '1', max_age: THIRTY_DAYS.to_s)

        built  = settings.built
        commit = settings.commit

        # Display the correct built date and commit SHA when running locally.
        built = Date.today.strftime('%d_%b_%Y') if built == '01_Jan_1970'
        commit = `git rev-parse --short HEAD` if commit == 'commit'
        erb :signin, layout: :simple_layout, locals: { title: 'Sign In',
                                                       built: built,
                                                       commit: commit,
                                                       environment: settings.environment }
      end

      post '/signin/?' do
        ldap_connection = LDAPConnection.new(settings.ldap_directory_host,
                                             settings.ldap_directory_port,
                                             settings.ldap_directory_base,
                                             settings.ldap_groups,
                                             logger)
        if user = User.authenticate(ldap_connection, params)
          session[:user] = user
          if request.cookies[NO_2FA_COOKIE]
            session[:valid_token] = true
            redirect_to_original_request
          else
            redirect '/signin/secondfactor'
          end
        else
          flash[:notice] = 'You could not be signed in. Did you enter the correct credentials?'
          redirect '/signin'
        end
      end

      get '/signin/secondfactor/?' do
        unless session[:user]
          flash[:notice] = 'Please sign in first.'
          redirect '/signin'
        end
        erb :second_factor, layout: :simple_layout, locals: { title: 'Sign In' }
      end

      post '/signin/secondfactor/?' do
        unless session[:user]
          flash[:notice] = 'Your session has expired. please sign in again.'
          redirect '/signin'
        end
        if session[:user].valid_code?(CLOCK_DRIFT, params)
          logger.info "'#{session[:user].display_name}' entered a valid 2FA token"
          if params[:rememberme]
            response.set_cookie(NO_2FA_COOKIE, value: '1', max_age: THIRTY_DAYS.to_s)
          else
            response.delete_cookie(NO_2FA_COOKIE)
          end
          session[:valid_token] = true
          redirect_to_original_request
        else
          logger.info "'#{session[:user].display_name}' entered an invalid 2FA token"
          flash[:notice] = 'The code you entered is incorrect. Please try again.'
          redirect '/signin/secondfactor'
        end
      end

      get '/signout' do
        logger.info "'#{session[:user].display_name}' signed out"
        session[:user]  = nil
        session[:valid_token] = nil
        flash[:notice] = 'You have been signed out.'
        redirect '/'
      end

      use Rack::ETag           # Add an ETag
      use Rack::ConditionalGet # Support caching
      use Rack::Deflater       # GZip
    end
  end
end
