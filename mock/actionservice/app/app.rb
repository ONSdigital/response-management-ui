require 'rack/deflater'

require_relative './routes/actions_route'
require_relative './routes/actionplans_route'

module BeyondMock
  class App < Sinatra::Application
    use Routes::Base
    use Routes::CaseFrameService
  end
end
