module BeyondMock
  module Routes
    class CaseFrameService < Base

      # Get the address information for the specified UPRN.
      get '/caseframeservice/addresses/:uprn' do
        erb :address_uprn, locals: { uprn: params['uprn'] }
      end

      # Get the address information for a postcode
      get '/caseframeservice/addresses/postcode/:postcode' do
        erb :address_postcode, locals: { postcode: params['postcode'] }
      end

    end
  end
end
