module BeyondMock
  module Routes
    class CaseFrameService < Base

      # Get all case event categories
      get '/categories' do
        erb :categories
      end

    end
  end
end
