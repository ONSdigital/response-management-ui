require 'rack/deflater'

require_relative './routes/base'
require_relative './routes/action_route'
require_relative './routes/actionplan_route'
require_relative './routes/actionplanjob_route'

module BeyondMock
  class App < Sinatra::Application
    use Routes::Base
    use Routes::ActionService
  end
end
