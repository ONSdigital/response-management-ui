module BeyondMock
  module Routes
    class CaseFrameService < Base

      # Get all MSOAs for the specified LA.
      get '/caseframeservice/lads/:ladid/msoas' do
        erb :msoas, locals: { local_authority_code: params['ladid'] }
      end

      # Get information for the specified LAD
      get '/caseframeservice/lads/:ladid' do
        erb :local_authority, locals: { local_authority_code: params['ladid'] }
      end

    end
  end
end
