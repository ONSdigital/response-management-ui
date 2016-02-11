module BeyondMock
  module Routes
    class CaseFrameService < Base

      # Get information for the specified MSOA..
      get '/caseframeservice/msoas/:msoaid' do
        erb :msoa, locals: { msoa_code: params['msoaid'] }
      end

      # Get address summaries for the specified MSOA
      get '/caseframeservice/msoas/:msoaid/addresssummaries' do
        erb :addresssummary, locals: { msoa_code: params['msoaid'] }
      end

    end
  end
end
