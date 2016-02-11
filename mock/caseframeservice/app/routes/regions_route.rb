module BeyondMock
  module Routes
    class CaseFrameService < Base

      # Get all regions.
      get '/caseframeservice/regions' do
        erb :regions
      end

      # Get information for the specified region..
      get '/caseframeservice/regions/:regionid' do
        erb :region, locals: { region_code: params['regionid'] }
      end

      # Get all LADs for the specified region.
      get '/caseframeservice/regions/:regionid/lads' do
        erb :local_authorities, locals: { region_code: params['regionid'] }
      end

    end
  end
end
