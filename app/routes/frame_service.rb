module Beyond
  module Routes
    class FrameService < Base

      # Get all cases for the selected address.
      get '/addresses/:uprn_code/cases' do | uprn_code|
        authenticate!
        cases = []

        RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/cases/uprn/#{uprn_code}") do |response, _request, _result, &_block|
          cases = JSON.parse(response).paginate(page: params[:page]) unless response.code == 204
        end

        if cases.any?
          cases.each do |uniqueCase|
            survey_id = uniqueCase['surveyId']
            sample_id = uniqueCase['sampleId']
            survey = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/surveys/#{survey_id}"))
            sample = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/samples/#{sample_id}"))
            uniqueCase['surveyDescription'] = survey['description']
            uniqueCase['name'] = sample['name']
          end
        end

        # Get the selected address details so they can be redisplayed for reference.
        address = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/addresses/#{uprn_code}"))
        coordinates = "#{address['latitude']},#{address['longitude']}"

        erb :cases, layout: :sidebar_layout,
                             locals: { title: "Cases for Address #{uprn_code}",
                                       uprn_code: uprn_code,
                                       cases: cases,
                                       address: address,
                                       coordinates: coordinates
                                     }
      end

      # Get a specific case.
      get '/case/:case_id' do |case_id|
        authenticate!
        events = []
        actions = []
        uniqueCase = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/cases/#{case_id}"))
        #events = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/cases/#{case_id}/events"))
        uprn_code = "#{uniqueCase['uprn']}"
        survey_id = "#{uniqueCase['surveyId']}"
        sample_id = "#{uniqueCase['sampleId']}"
        survey = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/surveys/#{survey_id}"))
        sample = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/samples/#{sample_id}"))

        RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/cases/#{case_id}/events") do |response, _request, _result, &_block|
          events = JSON.parse(response).paginate(page: params[:page]) unless response.code == 204
        end

        RestClient.get("http://#{settings.action_service_host}:#{settings.action_service_port}/actions/case/#{case_id}") do |response, _request, _result, &_block|
          actions = JSON.parse(response) unless response.code == 204
        end

          address = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/addresses/#{uprn_code}"))
          coordinates = "#{address['latitude']},#{address['longitude']}"
          erb :case_events, layout: :sidebar_layout,
                           locals: { title: "Event History for Case #{case_id}",
                                     uprn_code: uprn_code,
                                     caseid: case_id,
                                     uniqueCase: uniqueCase,
                                     events: events,
                                     address: address,
                                     coordinates: coordinates,
                                     survey: survey,
                                     sample: sample,
                                     actions: actions
                                    }

      end

      # Get all questionnaires for a specific case.
      get '/cases/:case_id/questionnaires' do |case_id|
        authenticate!
        questionnaires = []
        uniqueCase = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/cases/#{case_id}"))
        questionnaires = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/questionnaires/case/#{case_id}"))
        if uniqueCase.empty?
          erb :case_not_found, locals: { title: 'Case Not Found' }
        else
          uprn_code = "#{uniqueCase['uprn']}"
          address = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/addresses/#{uprn_code}"))
          coordinates = "#{address['latitude']},#{address['longitude']}"
          erb :case_questionnaire, layout: :sidebar_layout,
                           locals: { title: "Questionnaires for Case #{case_id}",
                                     uprn_code: address['uprn'],
                                     caseid: case_id,
                                     uniqueCase: uniqueCase,
                                     questionnaires: questionnaires,
                                     address: address,
                                     coordinates: coordinates }
        end
      end

      # Get a specific questionnaire.
      get '/questionnaires/:questionnaire_id' do |questionnaire_id|
        authenticate!
        questionnaire = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/cases/qid/#{questionnaire_id}"))

        if questionnaire.empty?
          erb :questionnaire_not_found, locals: { title: 'Questionnaire Not Found' }
        else
          follow_ups = JSON.parse(RestClient.get("http://#{settings.follow_up_service_host}:#{settings.follow_up_service_port}/FollowUpService/FollowUp/QuestionnaireId=#{questionnaire_id}")).paginate(page: params[:page])
          address = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/addresses/#{questionnaire['uprn']}"))
          coordinates = "#{address['latitude']},#{address['longitude']}"
          erb :follow_ups, layout: :sidebar_layout,
                           locals: { title: "Questionnaire #{questionnaire_id}",
                                     uprn_code: address['uprn'],
                                     case_id: address['caseId'],
                                     iac: address['iac'],
                                     questionnaire_id: questionnaire_id,
                                     follow_ups: follow_ups,
                                     questionnaire: questionnaire,
                                     address: address,
                                     coordinates: coordinates }
        end
      end

      # Postcode search.
      get '/postcode/:postcode' do |postcode|
        authenticate!
        addresses  = []
        search_url = "http://#{settings.frame_service_host}:#{settings.frame_service_port}/addresses/postcode/#{postcode}"

        # CTPA-477 Need to URI encode the postcode search string.
        RestClient.get(URI.encode(search_url)) do |response, _request, _result, &_block|
          addresses = JSON.parse(response).paginate(page: params[:page]) unless response.code == 404
        end

        erb :addresses_postcode, locals: { title: "Addresses for Postcode #{postcode}",
                                           addresses: addresses }
      end

      # Present a form for creating a new event.
      get '/case/:case_id/event/new' do |case_id|
      authenticate!
      action = "/case/#{case_id}/event"

        # Get groups from session[:user].groups and remove the duplicated collect-user
        groups = session[:user].groups
        groups -= ['collect-users']

      categories = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/categories?role=#{groups.first}"))
      erb :event, locals: { title: "Create Event for Case #{case_id}",
                                    action: action,
                                    method: :post,
                                    page: params[:page],
                                    eventtext: '',
                                    customername: '',
                                    customercontact: '',
                                    eventcategory: '',
                                    createdby: '',
                                    description_error: false,
                                    case_id: case_id,
                                    categories: categories
                                    }
      end

      # Create a new event.
      post '/case/:case_id/event' do |case_id|
        authenticate!

        #test for existence of description text
        form do
          field :eventtext, present: true
        end

        if form.failed?
          action = "/case/#{case_id}/event"
          # Get groups from session[:user].groups and remove the duplicated collect-user
          groups = session[:user].groups
          groups -= ['collect-users']
          categories = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/categories?role=#{groups.first}"))
          erb :event, locals: { title: "Create Event for Case #{case_id}",
                                        action: action,
                                        method: :post,
                                        page: params[:page],
                                        eventtext: '',
                                        customername: '',
                                        customercontact: '',
                                        eventcategory: params[:eventcategory],
                                        createdby: '',
                                        case_id: case_id,
                                        categories: categories
                                        }

        else
          user        = session[:user]
          name        = params[:customername]
          phone       = params[:customercontact]
          description = "#{params[:eventtext]}"
          description = "name: #{name} #{description}" if name.length > 0 && phone.length == 0
          description = "phone: #{phone} #{description}" if name.length == 0 && phone.length > 0
          description = "name: #{name} phone: #{phone} #{description}" if name.length > 0 && phone.length > 0

          RestClient.post("http://#{settings.frame_service_host}:#{settings.frame_service_port}/cases/#{case_id}/events",
                          { description: "#{description}",
                            category: params[:eventcategory],
                            createdBy: "#{user.user_id}"
                          }.to_json, content_type: :json, accept: :json
                         ) do |response, _request, _result, &_block|
            if response.code == 200
              flash[:notice] = 'Successfully created event.'
              actions = []

              if params[:eventcategory] == 'Closed' || params[:eventcategory] == 'IncorrectEscalation' || params[:eventcategory] == 'Undeliverable'
                  RestClient.get("http://#{settings.action_service_host}:#{settings.action_service_port}/actions/case/#{case_id}") do |response, _request, _result, &_block|
                  actions = JSON.parse(response).paginate(page: params[:page]) unless response.code == 204
                end
                if actions.any?
                  actions.each do |action|
                    if action['actionTypeName'] == 'GeneralEscalation' || action['actionTypeName'] == 'SurveyEscalation' || action['actionTypeName'] ==  'ComplaintEscalation'
                      action_id    = action['actionId']
                      feedback_xml = <<-XML
                        <p:actionFeedback xmlns:p="http://ons.gov.uk/ctp/response/action/message/feedback" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://ons.gov.uk/ctp/response/action/message/feedback actionFeedback.xsd">
                          <actionId>#{action_id}</actionId>
                          <situation></situation>
                          <outcome>REQUEST_COMPLETED</outcome>
                          <notes></notes>
                        </p:actionFeedback>
                      XML

                      RestClient.put("http://#{settings.action_service_host}:#{settings.action_service_port}/actions/#{action_id}/feedback",
                        feedback_xml, content_type: :xml) do |response, _request, _result, &_block|
                          if response.code == 200
                            logger.info 'Successfully completed action.'
                          else
                            logger.error response
                            error_flash('Unable to complete action', response)
                          end
                        end
                      end
                    end
                  end
                end
            else
              logger.error response
              error_flash('Unable to create event', response)
            end
          end

          event_url = "/case/#{case_id}"
          event_url += "?page=#{params[:page]}" if params[:page].present?
          redirect event_url
        end
      end
    end
  end
end
