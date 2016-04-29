module BeyondMock
  module Routes
    class ActionService < Base


      # Lists all actions, optionally filtered by ActionType and/or state.
      get '/actions' do
        if params[:state].nil? && params[:actiontype].nil?
          erb :actions
        elsif params[:state].nil? && !params[:actiontype].nil?
          erb :actions_actiontype, locals: { actiontype: params['actiontype'] }
        elsif !params[:state].nil? && params[:actiontype].nil?
          erb :actions_state, locals: { state: params['state'] }
        else
          erb :actions_actiontype_state, locals: { actiontype: params['actiontype'], state: params['state'] }
        end
      end

      # create an action
      post '/actions' do
        erb :new_actions
      end

      # Get the action details for a specified action
      get '/actions/:actionid' do
        erb :action, locals: { actionid: params['actionid'] }
      end

      # update an action
      put '/actions/:actionid' do
        erb :edit_action, locals: { actionid: params['actionid'] }
      end

      # update an action
      put '/actions/case/:caseid' do
        erb :edit_action_case, locals: { caseid: params['caseid'] }
      end

      # Get action details for a specified case
      get '/actions/case/:caseid' do
        erb :action_case, locals: { caseid: params['caseid'] }
      end

    end
  end
end
