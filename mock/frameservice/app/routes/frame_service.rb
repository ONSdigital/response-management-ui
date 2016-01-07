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

      # Get the address for the specified UPRN as path parameter
      get '/frameservice/addresses/:uprn/?' do
        erb :address, locals: { uprn: params['uprn'] }
      end

      # Update an existing address.
      put '/frameservice/addresses/:uprn' do
        erb :address, locals: { uprn: params['uprn'] }
      end

      # Get all questionnaires for the specified UPRN, questionnaire for the specified Token or QuestionnaireId as a query parameter
      get '/frameservice/questionnaires' do
        erb :questionnaires, locals: { questionnaireid: params['questionnaireid'], token: params['token'], uprn: params['uprn'], tracker: params['tracker'] }
      end

      # Get questionnaire for the specified questionnaireid as a path parameter
      get '/frameservice/questionnaires/:questionnaireid/?' do
        erb :questionnaire, locals: { questionnaireid: params['questionnaireid'] }
      end

      # Update an existing questionnaire.
      put '/frameservice/questionnaires/:questionnaireid/?' do
        erb :questionnaire, locals: { questionnaireid: params['questionnaireid'] }
      end

      # Create a new questionnaire.
      post '/frameservice/:formtype/questionnaires/?' do
        erb :new_questionnaire, locals: { formtype: params['formtype'] }
      end

    end
  end
end
