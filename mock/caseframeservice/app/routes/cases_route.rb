module BeyondMock
  module Routes
    class CaseFrameService < Base

      # Get the case information for the specified UPRN
      get '/cases/uprn/:uprn' do
        erb :cases, locals: { uprn: params['uprn'] }
      end

      # Get the case information for the specified questionnaire
      get '/cases/qid/:questionnaireid' do
        erb :case_qid, locals: { questionnaireid: params['questionnaireid'] }
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
      put '/cases/:caseid/events' do
        erb :case_events, locals: { caseid: params['caseid'] }
      end


    end
  end
end
