require 'sinatra'
require 'sinatra/content_for2'
require 'sinatra/flash'
require 'syslog/logger'
require 'will_paginate'
require 'will_paginate/array'
require 'rest_client'
require 'ons-ldap'
require 'json'
require 'yaml'
require 'open-uri'
require 'sinatra/formkeeper'
require 'csv'
require 'rack/session/redis'

require_relative '../lib/authentication'
require_relative '../models/user'

PROGRAM = 'responseoperations'.freeze
SESSION_EXPIRATION_PERIOD = 60 * 60 * 6

set :action_exporter_host,             ENV['RESPONSE_OPERATIONS_ACTIONEXPORTER_SERVICE_HOST']
set :action_exporter_port,             ENV['RESPONSE_OPERATIONS_ACTIONEXPORTER_SERVICE_PORT']
set :action_service_host,              ENV['RESPONSE_OPERATIONS_ACTION_SERVICE_HOST']
set :action_service_port,              ENV['RESPONSE_OPERATIONS_ACTION_SERVICE_PORT']
set :case_service_host,                ENV['RESPONSE_OPERATIONS_CASE_SERVICE_HOST']
set :case_service_port,                ENV['RESPONSE_OPERATIONS_CASE_SERVICE_PORT']
set :sample_service_host,              ENV['RESPONSE_OPERATIONS_SAMPLE_SERVICE_HOST']
set :sample_service_port,              ENV['RESPONSE_OPERATIONS_SAMPLE_SERVICE_PORT']
set :client_password,                  ENV['RESPONSE_OPERATIONS_CLIENT_PASSWORD']
set :client_user,                      ENV['RESPONSE_OPERATIONS_CLIENT_USER']
set :collection_exercise_service_host, ENV['RESPONSE_OPERATIONS_COLLECTION_EXERCISE_SERVICE_HOST']
set :collection_exercise_service_port, ENV['RESPONSE_OPERATIONS_COLLECTION_EXERCISE_SERVICE_PORT']
set :notifygateway_host,               ENV['RESPONSE_OPERATIONS_NOTIFYGATEWAY_SERVICE_HOST']
set :notifygateway_port,               ENV['RESPONSE_OPERATIONS_NOTIFYGATEWAY_SERVICE_PORT']
set :oauth_server,                     ENV['RESPONSE_OPERATIONS_OAUTHSERVER_HOST']
set :party_service_host,               ENV['RESPONSE_OPERATIONS_PARTY_SERVICE_HOST']
set :party_service_port,               ENV['RESPONSE_OPERATIONS_PARTY_SERVICE_PORT']
set :secure_message_service_host,      ENV['RESPONSE_OPERATIONS_SECURE_MESSAGE_SERVICE_HOST']
set :secure_message_service_port,      ENV['RESPONSE_OPERATIONS_SECURE_MESSAGE_SERVICE_PORT']
set :protocol,                         ENV['RESPONSE_OPERATIONS_HTTP_PROTOCOL']
set :security_user_name,               ENV['security_user_name']
set :security_user_password,           ENV['security_user_password']
set :security_realm,                   ENV['security_realm']

# Store Session in Redis
use Rack::Session::Redis, {
                            redis_server: 'redis://0.0.0.0:7379/0',
                            key:    'ras.rm.session',
                            expire_after: SESSION_EXPIRATION_PERIOD
                          }
                          
# Set global pagination options.
WillPaginate.per_page = 20

before do
  headers 'Content-Type' => 'text/html; charset=utf-8'
  protocol             = ENV['RAS_BACKSTAGE_UI_PROTOCOL']
  host                 = ENV['RAS_BACKSTAGE_UI_HOST']
  collection_exercises = ENV['RAS_BACKSTAGE_UI_COLLECTION_EXERCISES']
  collection_exercise  = ENV['BRES_2017_COLLECTION_EXERCISE']
  @secure_messages_url = "#{protocol}://#{settings.secure_message_service_host}"
  @bres_2017_url = "#{protocol}://#{host}/#{collection_exercises}/#{collection_exercise}" if host.present? && protocol.present? && collection_exercises.present? && collection_exercise.present?
end

# View helper for defining blocks inside views for rendering in templates.
helpers Sinatra::ContentFor2
helpers Authentication
helpers do

  # View helper for parsing and displaying JSON error responses.
  def error_flash(message, response)
    error = JSON.parse(response)
    if error['error']['timestamp']
      flash[:error] = "#{message}: #{error['error']['message']}<br>Please quote reference #{error['error']['timestamp']} when contacting support."
    elsif error['timestamp']
      flash[:error] = "#{message}: #{error['message']}<br>Please quote reference #{error['timestamp']} when contacting support."
    end
  end

  def error_flash_text(message, response)
    flash[:error] = "#{message}: #{response}"
  end

  # View helper for escaping HTML output.
  def h(text)
    Rack::Utils.escape_html(text)
  end
end

# Home page.
get '/' do
  authenticate!
  erb :index, locals: { title: 'Home' }
end
