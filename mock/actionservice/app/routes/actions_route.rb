module BeyondMock
  module Routes
    class CaseFrameService < Base


      # Get the action details for a specified action
      get '/actions' do
        erb :actions
      end

      # Get the action details for a specified action
      get '/actions/:actionid' do
        erb :action, locals: { actionid: params['actionid'] }
      end

      # Get action details for a specified case
      get '/actions/case/:caseid' do
        erb :action_case, locals: { caseid: params['caseid'] }
      end

    end
  end
end
