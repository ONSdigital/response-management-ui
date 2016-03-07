module BeyondMock
  module Routes
    class CaseFrameService < Base

      # Get all the sction plans
      get '/actionplans/jobs/:actionplanjobid' do
        erb :actionplansjobs, locals: {actionplanjobid: params['actionplanjobid']}
      end

      # Get information for the specified action plan
      get '/actionplans/:actionplanid/jobs' do
        erb :actionplanjob, locals: { actionplanid: params['actionplanid'] }
      end

    end
  end
end
