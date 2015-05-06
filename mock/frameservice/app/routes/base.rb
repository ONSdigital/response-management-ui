require 'sinatra/base'

module BeyondMock
  module Routes
    class Base < Sinatra::Application
      configure do

        # Set global view options.
        set :erb, escape_html: true
        set :views, File.dirname(__FILE__) + '/../views'
      end

      # Always send UTF-8 Content-Type HTTP header.
      before do
        headers 'Content-Type' => 'application/json; charset=utf-8'
      end

      # GZip responses.
      use Rack::Deflater
    end
  end
end
