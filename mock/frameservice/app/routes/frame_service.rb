module BeyondMock
  module Routes
    class FrameService < Base

      # Get all regions.
      get '/frameservice/regions/?' do
        erb :regions
      end

      # Get all LAs for the selected region.
      get '/frameservice/lads' do
        # URL would pass query string regionid=region_code, Sinatra parses query string and makes data avialable in params object
        # but only works on URL path
        erb :local_authorities, locals: { region_code: params['regionid'] }
      end

      # Get all MSOAs for the specified LA.
            get '/frameservice/msoas' do
        erb :msoas, locals: { local_authority_code: params['ladid'], questionnairecounts: params['questionnairecounts'] }
      end

      # Get all addresses for the specified MSOA, UPRN or QuestionnaireId as query parameter
      get '/frameservice/addresses' do
        erb :addresses, locals: { questionnaireid: params['questionnaireid'], uprn: params['uprn'], msoa11cd: params['msoa11cd'], notestoreview: params['notestoreview'] }
      end

      # Get the address for the specified UPRN.

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
