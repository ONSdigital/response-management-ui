# frozen_string_literal: true

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
  responses              = ''
  case_state             = ''
  party_id               = ''
  collection_exercise_id = ''
  casegroup_id           = ''
  sampleunituuid         = ''
  case_id                = ''
  uri                    = ''
  caseref                = ''

  RestClient::Request.execute(method: :get,
                              url: "#{settings.protocol}://#{settings.party_service_host}:#{settings.party_service_port}/party-api/v1/parties/type/B/ref/#{sampleunitref}",
                              user: settings.security_user_name,
                              password: settings.security_user_password,
                              realm: settings.security_realm) do |party_response, _request, _result, &_block|

    sampleunit = JSON.parse(party_response) unless party_response.code == 404
    if sampleunit.any?
      sampleunituuid = sampleunit['id']
      # find a case for the given partyid - from here get the case group and then return all cases for the originally supplied sampleunitref
      RestClient::Request.execute(method: :get,
                                  url: "#{settings.protocol}://#{settings.case_service_host}:#{settings.case_service_port}/cases/partyid/#{sampleunituuid}",
                                  user: settings.security_user_name,
                                  password: settings.security_user_password,
                                  realm: settings.security_realm) do |sample_response, _request, _result, &_block|
        sampleunitcases = JSON.parse(sample_response) unless sample_response.code == 404 || sample_response.code == 204
        if sampleunitcases.any?
          sampleunitcases.each do |sampleunitcase|
            casegroup_id = sampleunitcase['caseGroup']['id']
          end

          RestClient::Request.execute(method: :get,
                                      url: "#{settings.protocol}://#{settings.case_service_host}:#{settings.case_service_port}/cases/casegroupid/#{casegroup_id}",
                                      user: settings.security_user_name,
                                      password: settings.security_user_password,
                                      realm: settings.security_realm) do |cases_response, _request, _result, &_block|
            cases = JSON.parse(cases_response).paginate(page: params[:page]) unless cases_response.code == 404
            cases.each do |kase|
              caseref = kase['caseRef'] if kase['sampleUnitType'] == 'BI'

              if kase['sampleUnitType'] == 'B'
                case_id                = kase['id']
                party_id               = kase['partyId']
                ru_kase                = JSON.parse(RestClient::Request.execute(method: :get,
                                                                     url: "#{settings.protocol}://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}",
                                                                     user: settings.security_user_name,
                                                                     password: settings.security_user_password,
                                                                     realm: settings.security_realm))
                collection_exercise_id = ru_kase['caseGroup']['collectionExerciseId']
                responses  = kase['responses']
                case_state = kase['state']
                kase['respondent'] = 'Respondent Name'
              end
            end
          end

          RestClient::Request.execute(method: :get,
                                      url: "#{settings.protocol}://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}/events",
                                      user: settings.security_user_name,
                                      password: settings.security_user_password,
                                      realm: settings.security_realm) do |response, _request, _result, &_block|
            events = JSON.parse(response).paginate(page: params[:page]) unless response.code == 204
            events.each do |event|
              category_name         = event['category']
              category              = JSON.parse(RestClient::Request.execute(method: :get,
                                                                  url: "#{settings.protocol}://#{settings.case_service_host}:#{settings.case_service_port}/categories/name/#{category_name}",
                                                                  user: settings.security_user_name,
                                                                  password: settings.security_user_password,
                                                                  realm: settings.security_realm))
              event['categoryName'] = category['longDescription']
            end
          end

          RestClient::Request.execute(method: :get,
                                      url: "#{settings.protocol}://#{settings.action_service_host}:#{settings.action_service_port}/actions/case/#{case_id}",
                                      user: settings.security_user_name,
                                      password: settings.security_user_password,
                                      realm: settings.security_realm) do |response, _request, _result, &_block|
            actions = JSON.parse(response) unless response.code == 204
          end

          RestClient::Request.execute(method: :get,
                                      url: "#{settings.protocol}://#{settings.collection_exercise_service_host}:#{settings.collection_exercise_service_port}/collectionexercises/#{collection_exercise_id}",
                                      user: settings.security_user_name,
                                      password: settings.security_user_password,
                                      realm: settings.security_realm) do |respondent_response, _request, _result, &_block|
            collectionexercise = JSON.parse(respondent_response) unless respondent_response.code == 404
            survey_id = collectionexercise['surveyId']
          end

          respondents = sampleunit['associations']
          if respondents.any?
            respondents.each do |respondent|
              respondentuuid = respondent['partyId']
              RestClient::Request.execute(method: :get,
                                          url: "#{settings.protocol}://#{settings.party_service_host}:#{settings.party_service_port}/party-api/v1/respondents/id/#{respondentuuid}",
                                          user: settings.security_user_name,
                                          password: settings.security_user_password,
                                          realm: settings.security_realm) do |respondent_response, _request, _result, &_block|
                party_respondent = JSON.parse(respondent_response) unless respondent_response.code == 404
                params = {  respondent: party_respondent['id'],
                            reporting_unit: party_id,
                            survey: survey_id,
                            respondent_case: case_id,
                            collection_exercise: collection_exercise_id }
                url       = URI.parse "#{settings.protocol}://#{settings.secure_message_service_host}/create-message"
                url.query = URI.encode_www_form URI.decode_www_form(url.query || '').concat(params.to_a)
                respondent['url'] = url
                respondent['id'] = party_respondent['id']
                respondent['firstName'] = party_respondent['firstName']
                respondent['lastName'] = party_respondent['lastName']
                respondent['emailAddress'] = party_respondent['emailAddress']
                respondent['telephone'] = party_respondent['telephone']
                enrolments = respondent['enrolments']
                enrolments.each do |enrolment|
                  if enrolment['SurveyId'] == survey_id
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
  elsif sampleunit.any?
    title = "No Events for #{sampleunit['attributes']['entname1']}"
  else
    title = 'No matching reporting units'
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
                                                                 party_id: party_id,
                                                                 caseref: caseref }
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
  caseref = ''

  RestClient::Request.execute(method: :get,
                            url: "#{settings.protocol}://#{settings.case_service_host}:#{settings.case_service_port}/cases/partyid/#{party_id}",
                            user: settings.security_user_name,
                            password: settings.security_user_password,
                            realm: settings.security_realm) do |kase_response, _request, _result, &_block|

    kases = JSON.parse(kase_response).paginate(page: params[:page]) unless kase_response.code == 404

    kases.each do |kase|
      case_state = kase['state']
      case_id = kase['id']
      collection_exercise_id = kase['caseGroup']['collectionExerciseId']
      casegroup_id = kase['caseGroup']['id']

      RestClient::Request.execute(method: :get,
                                url: "#{settings.protocol}://#{settings.case_service_host}:#{settings.case_service_port}/cases/casegroupid/#{casegroup_id}",
                                user: settings.security_user_name,
                                password: settings.security_user_password,
                                realm: settings.security_realm) do |cases_response, _request, _result, &_block|

        cases = JSON.parse(cases_response).paginate(page: params[:page]) unless cases_response.code == 404
        cases.each do |kase_g|
          caseref = kase_g['caseRef'] if kase_g['sampleUnitType'] == 'BI'
        end
      end
    end

    RestClient::Request.execute(method: :get,
                            url: "#{settings.protocol}://#{settings.party_service_host}:#{settings.party_service_port}/party-api/v1/parties/type/B/ref/#{sampleunitref}",
                            user: settings.security_user_name,
                            password: settings.security_user_password,
                            realm: settings.security_realm) do |response, _request, _result, &_block|
      sampleunit = JSON.parse(response) unless response.code == 404
    end

    RestClient::Request.execute(method: :get,
                            url: "#{settings.protocol}://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}/events",
                            user: settings.security_user_name,
                            password: settings.security_user_password,
                            realm: settings.security_realm) do |response, _request, _result, &_block|
      events = JSON.parse(response).paginate(page: params[:page]) unless response.code == 204
      events.each do |event|
        category_name         = event['category']
        category              = JSON.parse(RestClient::Request.execute(method: :get,
                                                            url: "#{settings.protocol}://#{settings.case_service_host}:#{settings.case_service_port}/categories/name/#{category_name}",
                                                            user: settings.security_user_name,
                                                            password: settings.security_user_password,
                                                            realm: settings.security_realm))
        event['categoryName'] = category['longDescription']
      end
    end

    RestClient::Request.execute(method: :get,
                            url: "#{settings.protocol}://#{settings.action_service_host}:#{settings.action_service_port}/actions/case/#{case_id}",
                            user: settings.security_user_name,
                            password: settings.security_user_password,
                            realm: settings.security_realm) do |response, _request, _result, &_block|
      actions = JSON.parse(response) unless response.code == 204
    end

    RestClient::Request.execute(method: :get,
                            url: "#{settings.protocol}://#{settings.party_service_host}:#{settings.party_service_port}/party-api/v1/parties/type/B/ref/#{sampleunitref}",
                            user: settings.security_user_name,
                            password: settings.security_user_password,
                            realm: settings.security_realm) do |response, _request, _result, &_block|
      sampleunit = JSON.parse(response) unless response.code == 404
      sampleunituuid = sampleunit['id']
      RestClient::Request.execute(method: :get,
                                  url: "#{settings.protocol}://#{settings.party_service_host}:#{settings.party_service_port}/party-api/v1/respondents/id/#{party_id}",
                                  user: settings.security_user_name,
                                  password: settings.security_user_password,
                                  realm: settings.security_realm) do |respondent_response, _request, _result, &_block|
        respondents = JSON.parse(respondent_response) unless respondent_response.code == 404

        params = {  respondent: party_id,
                    reporting_unit: sampleunituuid,
                    survey: survey_id,
                    respondent_case: case_id,
                    collection_exercise: collection_exercise_id }
        url       = URI.parse "#{settings.protocol}://#{settings.secure_message_service_host}/create-message"
        url.query = URI.encode_www_form URI.decode_www_form(url.query || '').concat(params.to_a)
        respondents['url'] = url

      end

    end

    RestClient::Request.execute(method: :get,
                            url: "#{settings.protocol}://#{settings.collection_exercise_service_host}:#{settings.collection_exercise_service_port}/collectionexercises/#{collection_exercise_id}",
                            user: settings.security_user_name,
                            password: settings.security_user_password,
                            realm: settings.security_realm) do |respondent_response, _request, _result, &_block|
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
                                                             party_id: party_id,
                                                             caseref: caseref }
end

# sampleunitref search.
get '/sampleunitref/:sampleunitref' do |sampleunitref|
  authenticate!
  sampleunits = []

  RestClient::Request.execute(method: :get,
                            url: "#{settings.protocol}://#{settings.party_service_host}:#{settings.party_service_port}/party-api/v1/parties/type/B/ref/#{sampleunitref}",
                            user: settings.security_user_name,
                            password: settings.security_user_password,
                            realm: settings.security_realm) do |response, _request, _result, &_block|
    sampleunits = JSON.parse(response) unless response.code == 404
  end

  erb :addresses, locals: { title: "Addresses for Sample Unit Ref #{sampleunitref}",
                            sampleunits: sampleunits,
                            sampleunitref: sampleunitref }
end

get '/sampleunitref/:sampleunitref/cases/:case_id/events/:respondent_id/resend_verification_code' do |sampleunitref, case_id, respondent_id|

  RestClient::Request.execute(method: :get,
                          url: "#{settings.protocol}://#{settings.party_service_host}:#{settings.party_service_port}/party-api/v1/respondents/id/#{respondent_id}",
                          user: settings.security_user_name,
                          password: settings.security_user_password,
                          realm: settings.security_realm) do |respondent_response, _request, _result, &_block|
  respondents = JSON.parse(respondent_response) unless respondent_response.code == 404

  RestClient::Request.execute(method: :get,
                          url: "#{settings.protocol}://#{settings.party_service_host}:#{settings.party_service_port}/party-api/v1/resend-verification-email/#{respondent_id}",
                          user: settings.security_user_name,
                          password: settings.security_user_password,
                          realm: settings.security_realm) do |get_response, _request, _result, &_block|

      if get_response.code == 200
        flash[:notice] = 'Verification code successfully resent.'
        RestClient::Request.execute(method: :post,
                                    url: "#{settings.protocol}://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}/events",
                                    user: settings.security_user_name,
                                    password: settings.security_user_password,
                                    realm: settings.security_realm,
                                    payload: {
                                      "description": "Verification code successfully resent.",
                                      "category": "VERIFICATION_CODE_SENT",
                                      "subCategory": "nil",
                                      "createdBy": "#{session[:display_name]}"
                                    }.to_json,
                                    headers: {"Content-Type" => "application/json"},
                                    accept: :json) do |post_response_event, _request, _result, &_block|

          if post_response_event.code == 201
            flash[:notice] = 'Verification code successfully resent.'
          else
            logger.error post_response_event
            error_flash('Unable to create event', post_response_event)
          end
        end
      else
        logger.error get_response
        error_flash_text('Unable to send verification code', get_response)
      end
    end

  end

  event_url = "/sampleunitref/#{sampleunitref}/cases/"
  redirect event_url

end
