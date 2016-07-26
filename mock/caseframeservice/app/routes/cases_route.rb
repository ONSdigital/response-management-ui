module BeyondMock
  module Routes
    class CaseFrameService < Base

      # Get the case information for the specified UPRN
      get '/cases/uprn/:uprn' do
        erb :cases, locals: { uprn: params['uprn'] }
      end

      # Get the case information for the specified questionnaire
      get '/cases/questionnaire/:questionnaireid' do
        erb :case_questionnaire, locals: { questionnaireid: params['questionnaireid'] }
      end

      # Get the case information for the specified case
      get '/cases/:caseid' do
        erb :case, locals: { caseid: params['caseid'] }
      end

      # Get the history for the specified case
      get '/cases/:caseid/events' do
        erb :case_events, locals: { caseid: params['caseid'] }
      end

      # creates a case event
      post '/cases/:caseid/events' do
        erb :event, locals: { caseid: params['caseid'] }
      end

      # Lists all case IDs for an action plan's cases, optionally filtered by case state
      get '/cases/actionplan/:actionplanid' do
        erb :cases_actionplan, locals: { actionplanid: params['actionplanid'] }
      end

    end
  end
end
