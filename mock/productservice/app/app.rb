require 'rack/deflater'

require_relative './routes/base'
require_relative './routes/product_service'

module BeyondMock
  class App < Sinatra::Application
    use Routes::Base
    use Routes::ProductService
  end
end
