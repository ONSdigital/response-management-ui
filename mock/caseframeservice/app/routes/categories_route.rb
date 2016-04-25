module BeyondMock
  module Routes
    class CaseFrameService < Base

      # Get case event categories filtered by role
      get '/categories' do
        role = params['role']
        erb :categories, locals: { role: role }
      end

    end
  end
end
