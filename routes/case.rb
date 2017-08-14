require_relative '../lib/core_ext/nilclass'
require_relative '../lib/core_ext/string'
require_relative '../lib/core_ext/object'

logger = Syslog::Logger.new(PROGRAM, Syslog::LOG_USER)

helpers do
  def coordinates_for(address)
    "#{address['latitude']},#{address['longitude']}"
  end

  def format_postcode(postcode)
    postcode.upcase!
    return postcode if postcode.length == 8

    # Add a space before the inward code, which is always three characters long.
    "#{postcode[0, postcode.length - 3]} #{postcode[-3, 3]}"
  end

  def url_format(str)
    str.gsub(/\s+/, '').downcase
  end
end

# Get Reporting Unit for sampleunitref
get '/sampleunitref/:sampleunitref/cases/?' do |sampleunitref|
  authenticate!
  events                 = []
  actions                = []
  sampleunit             = []
  survey_id              = []
  respondents            = []
  collectionexercise     = []
  sampleunitcases        = []
  cases                  = []
  kase                   = ''
  responses              = ''
  case_state             = ''
  party_id               = ''
  collection_exercise_id = ''
  casegroup_id           = ''
  sampleunituuid         = ''
  case_id                = ''
  uri                    = ''

  RestClient.get("#{settings.protocol}://#{settings.party_service_host}:#{settings.party_service_port}/party-api/v1/parties/type/B/ref/#{sampleunitref}") do |response, _request, _result, &_block|
    sampleunit = JSON.parse(response) unless response.code == 404
    if sampleunit.any?
      sampleunituuid = sampleunit['id']
      # find a case for the given partyid - from here get the case group and then return all cases for the originally supplied sampleunitref
      RestClient.get("#{settings.protocol}://#{settings.case_service_host}:#{settings.case_service_port}/cases/partyid/#{sampleunituuid}") do |sample_response, _request, _result, &_block|
        sampleunitcases = JSON.parse(sample_response) unless sample_response.code == 404 || sample_response.code == 204
        if sampleunitcases.any?
          sampleunitcases.each do |sampleunitcase|
            casegroup_id = sampleunitcase['caseGroup']['id']
          end

          RestClient.get("#{settings.protocol}://#{settings.case_service_host}:#{settings.case_service_port}/cases/casegroupid/#{casegroup_id}") do |cases_response, _request, _result, &_block|
            cases = JSON.parse(cases_response).paginate(page: params[:page]) unless cases_response.code == 404
            cases.each do |kase|
              if kase['sampleUnitType'] == 'B'
                case_id                = kase['id']
                party_id               = kase['partyId']
                ru_kase                = JSON.parse(RestClient.get("#{settings.protocol}://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}"))
                collection_exercise_id = ru_kase['caseGroup']['collectionExerciseId']
                responses  = kase['responses']
                case_state = kase['state']
                kase['respondent'] = 'Respondent Name'
              end
            end
          end

          RestClient.get("#{settings.protocol}://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}/events") do |response, _request, _result, &_block|
            events = JSON.parse(response).paginate(page: params[:page]) unless response.code == 204
            events.each do |event|
              category_name         = event['category']
              category              = JSON.parse(RestClient.get("#{settings.protocol}://#{settings.case_service_host}:#{settings.case_service_port}/categories/name/#{category_name}"))
              event['categoryName'] = category['longDescription']
            end
          end

          RestClient.get("#{settings.protocol}://#{settings.action_service_host}:#{settings.action_service_port}/actions/case/#{case_id}") do |response, _request, _result, &_block|
            actions = JSON.parse(response) unless response.code == 204
          end

          RestClient.get("#{settings.protocol}://#{settings.collection_exercise_service_host}:#{settings.collection_exercise_service_port}/collectionexercises/#{collection_exercise_id}") do |respondent_response, _request, _result, &_block|
            collectionexercise = JSON.parse(respondent_response) unless respondent_response.code == 404
            survey_id = collectionexercise['surveyId']
          end

          respondents = sampleunit['associations']
          if respondents.any?
            respondents.each do |respondent|
              respondentuuid = respondent['partyId']
              RestClient.get("#{settings.protocol}://#{settings.party_service_host}:#{settings.party_service_port}/party-api/v1/respondents/id/#{respondentuuid}") do |respondent_response, _request, _result, &_block|
                party_respondent = JSON.parse(respondent_response) unless respondent_response.code == 404
                params = {  respondent: party_respondent['id'],
                            reporting_unit: party_id,
                            survey: survey_id,
                            respondent_case: case_id,
                            collection_exercise: collection_exercise_id }
                url       = URI.parse "#{settings.protocol}://#{settings.secure_message_service_host}"
                url.query = URI.encode_www_form URI.decode_www_form(url.query || '').concat(params.to_a)
                respondent['url'] = url
                respondent['id'] = party_respondent['id']
                respondent['firstName'] = party_respondent['firstName']
                respondent['lastName'] = party_respondent['lastName']
                respondent['emailAddress'] = party_respondent['emailAddress']
                respondent['telephone'] = party_respondent['telephone']
                enrolments = respondent['enrolments']
                enrolments.each do |enrolment|
                  if enrolment['SurveyId'] = survey_id
                    respondent['status'] = enrolment['enrolmentStatus']
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  if collectionexercise.any?
    title = "#{collectionexercise['name']} for #{sampleunit['attributes']['entname1']}"
  else
    if sampleunit.any?
      title = "No Events for #{sampleunit['attributes']['entname1']}"
    else
      title = 'No matching Reporting Units'
    end
  end

  erb :reporting_unit_events, layout: :sidebar_layout, locals: { title: title,
                                                                 case_id: case_id,
                                                                 sampleunit: sampleunit,
                                                                 sampleunitref: sampleunitref,
                                                                 kase: kase,
                                                                 events: events,
                                                                 responses: responses,
                                                                 actions: actions,
                                                                 case_state: case_state,
                                                                 respondents: respondents,
                                                                 collection_exercise_id: collection_exercise_id,
                                                                 survey_id: survey_id,
                                                                 party_id: party_id }
end

# Get a specific case.
get '/sampleunitref/:sampleunitref/cases/:party_id/events?' do |sampleunitref, party_id|
  authenticate!
  events     = []
  actions    = []
  sampleunit = []
  survey_id = []
  respondents = []
  sampleunituuid = ''
  case_id = ''
  collectionexercise = []
  case_state = ''
  collection_exercise_id = ''

  kases       = JSON.parse(RestClient.get("#{settings.protocol}://#{settings.case_service_host}:#{settings.case_service_port}/cases/partyid/#{party_id}"))
  kases.each do | kase |
    case_state = kase['state']
    case_id = kase['id']
    collection_exercise_id = kase['caseGroup']['collectionExerciseId']

    RestClient.get("#{settings.protocol}://#{settings.party_service_host}:#{settings.party_service_port}/party-api/v1/parties/type/B/ref/#{sampleunitref}") do |response, _request, _result, &_block|
      sampleunit = JSON.parse(response) unless response.code == 404
    end

    RestClient.get("#{settings.protocol}://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}/events") do |response, _request, _result, &_block|
      events = JSON.parse(response).paginate(page: params[:page]) unless response.code == 204
      events.each do |event|
        category_name         = event['category']
        category              = JSON.parse(RestClient.get("#{settings.protocol}://#{settings.case_service_host}:#{settings.case_service_port}/categories/name/#{category_name}"))
        event['categoryName'] = category['longDescription']
      end
    end

    RestClient.get("#{settings.protocol}://#{settings.action_service_host}:#{settings.action_service_port}/actions/case/#{case_id}") do |response, _request, _result, &_block|
      actions = JSON.parse(response) unless response.code == 204
    end

    RestClient.get("#{settings.protocol}://#{settings.party_service_host}:#{settings.party_service_port}/party-api/v1/parties/type/B/ref/#{sampleunitref}") do |response, _request, _result, &_block|
      sampleunit = JSON.parse(response) unless response.code == 404
      sampleunituuid = sampleunit['id']
      RestClient.get("#{settings.protocol}://#{settings.party_service_host}:#{settings.party_service_port}/party-api/v1/respondents/id/#{party_id}") do |respondent_response, _request, _result, &_block|
        respondents = JSON.parse(respondent_response) unless respondent_response.code == 404

        params = {  respondent: party_id,
                    reporting_unit: sampleunituuid,
                    survey: survey_id,
                    respondent_case: case_id,
                    collection_exercise: collection_exercise_id }
        url       = URI.parse "#{settings.protocol}://#{settings.secure_message_service_host}"
        url.query = URI.encode_www_form URI.decode_www_form(url.query || '').concat(params.to_a)
        respondents['url'] = url

      end

    end

    RestClient.get("#{settings.protocol}://#{settings.collection_exercise_service_host}:#{settings.collection_exercise_service_port}/collectionexercises/#{collection_exercise_id}") do |respondent_response, _request, _result, &_block|
      collectionexercise = JSON.parse(respondent_response) unless respondent_response.code == 404
      survey_id = collectionexercise['surveyId']
    end
  end

  erb :respondent_events, layout: :sidebar_layout, locals: { title: "#{collectionexercise['name']} for respondent #{respondents['firstName']} #{respondents['lastName']} (#{sampleunit['attributes']['entname1']})",
                                                             case_id: case_id,
                                                             sampleunit: sampleunit,
                                                             sampleunitref: sampleunitref,
                                                             events: events,
                                                             actions: actions,
                                                             case_state: case_state,
                                                             respondents: respondents,
                                                             collection_exercise_id: collection_exercise_id,
                                                             survey_id: survey_id,
                                                             party_id: party_id }
end

# sampleunitref search.
get '/sampleunitref/:sampleunitref' do |sampleunitref|
  authenticate!
  sampleunits = []

  RestClient.get("#{settings.protocol}://#{settings.party_service_host}:#{settings.party_service_port}/party-api/v1/parties/type/B/ref/#{sampleunitref}") do |response, _request, _result, &_block|
    sampleunits = JSON.parse(response) unless response.code == 404
  end

  erb :addresses, locals: { title: "Addresses for Sample Unit Ref #{sampleunitref}",
                            sampleunits: sampleunits,
                            sampleunitref: sampleunitref }
end

get '/sampleunitref/:sampleunitref/cases/:case_id/events/:respondent_id/resend_verification_code' do |sampleunitref, case_id, respondent_id|

  RestClient.get("#{settings.protocol}://#{settings.party_service_host}:#{settings.party_service_port}/party-api/v1/respondents/id/#{respondent_id}") do |respondent_response, _request, _result, &_block|
    respondents = JSON.parse(respondent_response) unless respondent_response.code == 404

    RestClient.post("#{settings.protocol}://#{settings.notifygateway_host}:#{settings.notifygateway_port}/emails/#{settings.email_template_id}",
                    {
                      emailAddress: respondents['emailAddress']
                    }.to_json, content_type: :json, accept: :json) do |post_response, _request, _result, &_block|

      if post_response.code == 201
        flash[:notice] = 'Verification code successfully resent.'

        RestClient.post("#{settings.protocol}://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}/events",
                        {
                          description: 'Verification code successfully resent.',
                          category: 'VERIFICATION_CODE_SENT',
                          subCategory: nil,
                          createdBy: session[:display_name]
                        }.to_json, content_type: :json, accept: :json) do |post_response_event, _request, _result, &_block|

          if post_response_event.code == 201
            flash[:notice] = 'Verification code successfully resent.'
          else
            logger.error post_response_event
            error_flash('Unable to create event', post_response_event)
          end
        end

      else
        logger.error post_response
        error_flash('Unable to send verification code', post_response)
      end
    end

  end

  event_url = "/sampleunitref/#{sampleunitref}/cases/"
  redirect event_url

end
