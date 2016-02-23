module BeyondMock
  module Routes
    class CaseFrameService < Base

      # Get the action details for a specified action
      get '/events' do
        erb :events
      end


    end
  end
end
