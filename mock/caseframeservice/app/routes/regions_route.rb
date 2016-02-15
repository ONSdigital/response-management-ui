module BeyondMock
  module Routes
    class CaseFrameService < Base

      # Get all regions.
      get '/regions' do
        erb :regions
      end

      # Get information for the specified region..
      get '/regions/:regionid' do
        erb :region, locals: { regionCode: params['regionid'] }
      end

      # Get all LADs for the specified region.
      get '/regions/:regionid/lads' do
        erb :local_authorities, locals: { regionCode: params['regionid'] }
      end

    end
  end
end
