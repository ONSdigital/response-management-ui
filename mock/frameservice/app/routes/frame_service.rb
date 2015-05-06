module BeyondMock
  module Routes
    class FrameService < Base

      # Get all regions.
      get '/frameservice/regions' do
        erb :regions
      end

      # Get all LAs for the specified region.
      get '/frameservice/lads?regionid=:region_code' do
        erb :local_authorities
      end

      # Get all caseloads for the specified LA.
      get '/frameservice/caseloads?ladid=:local_authority_code' do
        erb :caseloads
      end

      # Get all addresses for the specified caseload.
      get '/frameservice/addresses?caseload=:caseload_code' do
        erb :addresses
      end

      # Get all the addresses to review for the selected caseload.
      get '/frameservice/addresse?caseloadid=:caseload_code&notestoreview=true' do
        erb :addresses
      end

      # Create a new address.
      post '/frameservice/addresses' do
        erb :new_address
      end

      # Update an existing address.
      put '/frameservice/addresses/:address_id' do
        erb :edit_address
      end

      # Get all questionnaires for the specified address.
      get '/frameservice/questionnaires?addressid=:address_id' do
        erb :questionnaires
      end

      # Create a new questionnaire.
      post '/frameservice/questionnaires' do
        erb :new_questionnaire
      end

      # Update an existing questionnaire.
      put '/frameservice/questionnaires/:questionnaire_id' do
        erb :edit_questionnaire
      end

      # Get the specified address.
      get '/frameservice/addresses/:address_id' do
        erb :address
      end

      # Get the specified questionnaire.
      get '/frameservice/questionnaires/:questionnaire_id' do
        erb :questionnaire
      end
    end
  end
end
