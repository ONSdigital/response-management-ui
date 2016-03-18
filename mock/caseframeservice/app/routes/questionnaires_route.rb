module BeyondMock
  module Routes
    class CaseFrameService < Base

      # Get questionnaire details for a specified iac
      get '/questionnaires/iac/:iac' do
        erb :questionnaire_iac, locals: { iac: params['iac'] }
      end

      # Get questionnaire details for a specified case
      get '/questionnaires/case/:caseid' do
        erb :questionnaire_case, locals: { caseid: params['caseid'] }
      end

      # Confirms a response has been received in the Survey Data Exchange
      put '/questionnaires/:questionnaireid/response' do
        erb :questionnaire, locals: { questionnaireid: params['questionnaireid'] }
      end

    end
  end
end
