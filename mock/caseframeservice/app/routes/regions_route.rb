module BeyondMock
  module Routes
    class CaseFrameService < Base

      # Get all regions.
      get '/regions' do
        erb :regions
      end

      # Get information for the specified region..
      get '/regions/:regionid' do
        erb :region, locals: { region_code: params['regionid'] }
      end

      # Get all LADs for the specified region.
      get '/regions/:regionid/lads' do
        erb :local_authorities, locals: { region_code: params['regionid'] }
      end

    end
  end
end
