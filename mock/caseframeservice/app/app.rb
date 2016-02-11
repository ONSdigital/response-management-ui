require 'rack/deflater'

require_relative './routes/base'
require_relative './routes/regions_route'
require_relative './routes/lads_route'
require_relative './routes/msoas_route'
require_relative './routes/addresses_route'

module BeyondMock
  class App < Sinatra::Application
    use Routes::Base
    use Routes::CaseFrameService
  end
end
