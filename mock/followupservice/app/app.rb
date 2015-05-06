require 'rack/deflater'

require_relative './routes/base'
require_relative './routes/follow_up_service'

module BeyondMock
  class App < Sinatra::Application
    use Routes::Base
    use Routes::FollowUpService
  end
end
