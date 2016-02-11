module BeyondMock
  module Routes
    class CaseFrameService < Base

      # Get all surveys
      get '/surveys' do
        erb :surveys
      end

      # Get information for the specified survey
      get '/surveys/:surveyid' do
        erb :survey, locals: { surveyid: params['surveyid'] }
      end

    end
  end
end
