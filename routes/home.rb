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

PROGRAM = 'responseoperations'.freeze
SESSION_EXPIRATION_PERIOD = 60 * 60 * 6

# Load various settings from a configuration file.
config = YAML.load_file(File.join(__dir__, '../config.yml'))
set :protocol, config['http']['protocol']
set :action_service_host, config['action-webservice']['host']
set :action_service_port, config['action-webservice']['port']
set :case_service_host, config['case-webservice']['host']
set :case_service_port, config['case-webservice']['port']
set :party_service_host, config['party-webservice']['host']
set :party_service_port, config['party-webservice']['port']
set :action_exporter_host, config['action-exporter-webservice']['host']
set :action_exporter_port, config['action-exporter-webservice']['port']
set :action_exporter_user, config['action-exporter-webservice']['user']
set :action_exporter_password, config['action-exporter-webservice']['password']

# Display badges with the host, built date, commit SHA and environment on the
# Sign In screen in non-production environments.
set :host, `hostname`.strip.gsub(/-/, '--')
set :built, config['badges']['built']
set :commit, config['badges']['commit']
set :environment, config['badges']['environment']

# Expire sessions after SESSION_EXPIRATION_PERIOD of inactivity
use Rack::Session::Cookie, key: 'rack.session', path: '/',
                           secret: 'eb46fa947d8411e5996329c9ef0ba35d',
                           expire_after: SESSION_EXPIRATION_PERIOD

# Set global pagination options.
WillPaginate.per_page = 20

# Always send UTF-8 Content-Type HTTP header.
before do
  headers 'Content-Type' => 'text/html; charset=utf-8'
end

# View helper for defining blocks inside views for rendering in templates.
helpers Sinatra::ContentFor2
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

  # View helper for escaping HTML output.
  def h(text)
    Rack::Utils.escape_html(text)
  end
end

# Home page.
get '/' do
  #authenticate!
  erb :index, locals: { title: 'Home' }
end
