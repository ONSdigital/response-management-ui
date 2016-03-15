module BeyondMock
  module Routes
    class ActionService < Base

      # get Action Plan Jobs
      get '/actionplans/jobs/:actionplanjobid' do
        erb :actionplanjob, locals: {actionplanjobid: params['actionplanjobid']}
      end

      # List Action Plan jobs
      get '/actionplans/:actionplanid/jobs' do
        erb :actionplanjobs, locals: { actionplanid: params['actionplanid'] }
      end

    end
  end
end
