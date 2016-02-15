module BeyondMock
  module Routes
    class CaseFrameService < Base

      # Get information for the specified MSOA..
      get '/msoas/:msoaid' do
        erb :msoa, locals: { msoaCode: params['msoaid'] }
      end

      # Get address summaries for the specified MSOA
      get '/msoas/:msoaid/addresssummaries' do
        erb :addresssummary, locals: { msoaCode: params['msoaid'] }
      end

    end
  end
end
