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

    end
  end
end
