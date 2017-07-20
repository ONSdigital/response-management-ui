require 'rubygems'
require 'bundler'

Bundler.require

require_relative 'routes/home'
require_relative 'routes/error'
require_relative 'routes/case'
require_relative 'routes/reports'
require_relative 'routes/respondent'
require_relative 'routes/authentication'		

require 'rack/etag'
require 'rack/conditionalget'
require 'rack/deflater'

use Rack::ETag            # Add an ETag
use Rack::ConditionalGet  # Support caching
use Rack::Deflater        # GZip

run Sinatra::Application
