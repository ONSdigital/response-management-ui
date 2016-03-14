module BeyondMock
  module Routes
    class ActionService < Base

      # List Action Plans
      get '/actionplans' do
        erb :actionplans
      end

      # Get Action Plan
      get '/actionplans/:actionplanid' do
        erb :actionplan, locals: { actionplanid: params['actionplanid'] }
      end

      # List Action Rlues for Action Plan
      get '/actionplans/:actionplanid/rules' do
        erb :actionplanrules, locals: { actionplanid: params['actionplanid'] }
      end

    end
  end
end
