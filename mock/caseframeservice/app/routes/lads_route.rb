module BeyondMock
  module Routes
    class CaseFrameService < Base

      # Get all MSOAs for the specified LA.
      get '/lads/:ladid/msoas' do
        erb :msoas, locals: { localAuthorityCode: params['ladid'] }
      end

      # Get information for the specified LAD
      get '/lads/:ladid' do
        erb :local_authority, locals: { localAuthorityCode: params['ladid'] }
      end

    end
  end
end
