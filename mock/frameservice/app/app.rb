require 'rack/deflater'

require_relative './routes/base'
require_relative './routes/frame_service'

module BeyondMock
  class App < Sinatra::Application
    use Routes::Base
    use Routes::FrameService
  end
end
