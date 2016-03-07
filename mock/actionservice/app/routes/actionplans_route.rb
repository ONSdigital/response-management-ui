module BeyondMock
  module Routes
    class CaseFrameService < Base

      # Get all the sction plans
      get '/actionplans' do
        erb :actionplans
      end

      # Get information for the specified action plan
      get '/actionplans/:actionplanid' do
        erb :actionplan, locals: { actionplanid: params['actionplanid'] }
      end

    end
  end
end
