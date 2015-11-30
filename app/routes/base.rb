require 'sinatra/content_for2'
require 'sinatra/flash'
require 'sinatra/formkeeper'
require 'will_paginate'
require 'will_paginate/array'
require 'rest_client'
require 'json'
require 'yaml'

module Beyond
  module Routes
    class Base < Sinatra::Application
      configure do

        # Load various settings from a configuration file.
        config = YAML.load_file(File.join(__dir__, '../../config/config.yml'))
        set :respgen_service_host, config['response-gen-webservice']['host']
        set :respgen_service_port, config['response-gen-webservice']['port']
        set :frame_service_host, config['frame-webservice']['host']
        set :frame_service_port, config['frame-webservice']['port']
        set :follow_up_service_host, config['follow-up-webservice']['host']
        set :follow_up_service_port, config['follow-up-webservice']['port']
        set :google_maps_api_key, config['google-maps']['api-key']

        # Need to enable sessions for the flash to work.
        enable :sessions
        set :session_secret, 'fb7eea3c119e11e483d5b2227cce2b54'

        # Set global view options.
        set :erb, escape_html: true
        set :views, File.dirname(__FILE__) + '/../views'
        set :public_folder, File.dirname(__FILE__) + '/../../public'

        # Set global pagination options.
        WillPaginate.per_page = 20
      end

      # View helper for defining blocks inside views for rendering in templates.
      helpers Sinatra::ContentFor2

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

      # Error pages.
      error 404 do
        erb :not_found, locals: { title: '404 Not Found' }
      end

      error 500 do
        erb :internal_server_error, locals: { title: '500 Internal Server Error' }
      end

      # Home page.
      get '/' do
        erb :index, locals: { title: 'Home' }
      end

      use Rack::ETag           # Add an ETag
      use Rack::ConditionalGet # Support caching
      use Rack::Deflater       # GZip
    end
  end
end
