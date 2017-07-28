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

# Get all cases for the selected address.
get '/sampleunitref/:sampleunitref/cases/?' do |sampleunitref|
  authenticate!
  cases      = []
  casegroups = []
  casetype   = []
  sample_id  = ''
  sampleunit = []
  casegroup_id = ''
  sampleunitcases = []
  respondent = []
  sampleunituuid = ''
  collectionexerciseid = ''
  collectionexercisename = ''

  RestClient.get("#{settings.protocol}://#{settings.party_service_host}:#{settings.party_service_port}/party-api/v1/parties/type/B/ref/#{sampleunitref}") do |response, _request, _result, &_block|
    sampleunit = JSON.parse(response) unless response.code == 404
    if sampleunit.any?
      sampleunituuid = sampleunit['id']
      # find a case for the given partyid - from here get the case group and then return all cases for the originally supplied sampleunitref
      RestClient.get("#{settings.protocol}://#{settings.case_service_host}:#{settings.case_service_port}/cases/partyid/#{sampleunituuid}") do |sample_response, _request, _result, &_block|
        sampleunitcases = JSON.parse(sample_response) unless sample_response.code == 404 || sample_response.code == 204
        sampleunitcases.each do |sampleunitcase|
          casegroup_id = sampleunitcase['caseGroup']['id']
          collectionexerciseid = sampleunitcase['caseGroup']['collectionExerciseId']
        end
        RestClient.get("#{settings.protocol}://#{settings.collection_exercise_service_host}:#{settings.collection_exercise_service_port}/collectionexercises/#{collectionexerciseid}") do |respondent_response, _request, _result, &_block|
          collectionexercise = JSON.parse(respondent_response) unless respondent_response.code == 404
          collectionexercisename = collectionexercise['name']
        end
        RestClient.get("#{settings.protocol}://#{settings.case_service_host}:#{settings.case_service_port}/cases/casegroupid/#{casegroup_id}") do |cases_response, _request, _result, &_block|
          cases = JSON.parse(cases_response).paginate(page: params[:page]) unless cases_response.code == 404
          cases.each do |kase|
            kase['respondent'] = 'Respondent Name'
          end
        end
        RestClient.get("#{settings.protocol}://#{settings.party_service_host}:#{settings.party_service_port}/party-api/v1/respondents/id/#{sampleunituuid}") do |respondent_response, _request, _result, &_block|
          respondent = JSON.parse(respondent_response) unless respondent_response.code == 404
        end
      end
    end
  end

  # Get the selected address details so they can be displayed for reference.
  erb :cases, layout: :sidebar_layout, locals: { title: "Cases for Sample Unit Ref #{sampleunitref}",
                                                 sampleunitref: sampleunitref,
                                                 sampleunit: sampleunit,
                                                 cases: cases,
                                                 collectionexercisename: collectionexercisename }
end

# Get a specific case.
get '/sampleunitref/:sampleunitref/cases/:case_id/events?' do |sampleunitref, case_id|
  authenticate!
  events     = []
  actions    = []
  sampleunit = []
  kase       = JSON.parse(RestClient.get("#{settings.protocol}://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}"))
  responses  = kase['responses']
  case_state = kase['state']
  party_id = kase['partyId']
  collection_exercise_id = kase['caseGroup']['collectionExerciseId']
  survey_id  = []
  respondent = []
  sampleunituuid = ''

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
      respondent = JSON.parse(respondent_response) unless respondent_response.code == 404
    end

  end

  RestClient.get("#{settings.protocol}://#{settings.collection_exercise_service_host}:#{settings.collection_exercise_service_port}/collectionexercises/#{collection_exercise_id}") do |respondent_response, _request, _result, &_block|
    collectionexercise = JSON.parse(respondent_response) unless respondent_response.code == 404
    survey_id = collectionexercise['surveyId']
  end

  url = "#{settings.protocol}://#{settings.secure_message_service_host}"
  params = {  respondentId: respondent['id'],
              caseId: kase['id'],
              collectionExerciseId: collection_exercise_id,
              surveyId: survey_id,
              reportingUnitId: party_id }
  uri       = URI.parse url
  uri.query = URI.encode_www_form URI.decode_www_form(uri.query || '').concat(params.to_a)

  erb :case_events, layout: :sidebar_layout, locals: { title: "Event History for Case #{case_id}",
                                                       case_id: case_id,
                                                       sampleunit: sampleunit,
                                                       sampleunitref: sampleunitref,
                                                       kase: kase,
                                                       events: events,
                                                       responses: responses,
                                                       actions: actions,
                                                       case_state: case_state,
                                                       respondent: respondent,
                                                       collection_exercise_id: collection_exercise_id,
                                                       survey_id: survey_id,
                                                       party_id: party_id,
                                                       secure_message_url: uri }
end

# Postcode search.
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

# Present a form for creating a new event.
get '/sampleunitref/:sampleunitref/cases/:case_id/event/new' do |sampleunitref, case_id|
  authenticate!
  actions    = []
  role       = 'collect-csos'
  kase       = JSON.parse(RestClient.get("#{settings.protocol}://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}"))

  categories = JSON.parse(RestClient.get("#{settings.protocol}://#{settings.case_service_host}:#{settings.case_service_port}/categories"))
  erb :event, locals: { title: "Create Event for Case #{case_id}",
                        action: "/sampleunitref/#{sampleunitref}/cases/#{case_id}/event",
                        method: :post,
                        page: params[:page],
                        eventtext: '',
                        customertitle: '',
                        customerforename: '',
                        customersurname: '',
                        customercontact: '',
                        eventcategory: '',
                        createdby: '',
                        categories: categories,
                        case_id: case_id,
                        sampleunitref: sampleunitref }
end

# Create a new event.
post '/sampleunitref/:sampleunitref/cases/:case_id/event' do |sampleunitref, case_id|
  authenticate!

  customertitle    = params[:customertitle]
  customerforename = params[:customerforename]
  customersurname  = params[:customersurname]
  name             = params[:customertitle] + ' ' + params[:customerforename] + ' ' + params[:customersurname]
  customercontact  = params[:customercontact]
  eventtext        = params[:eventtext]

  if params[:eventcategory] == 'FIELD_COMPLAINT_ESCALATED' || params[:eventcategory] == 'FIELD_EMERGENCY_ESCALATED' || params[:eventcategory] == 'GENERAL_ENQUIRY_ESCALATED' || params[:eventcategory] == 'GENERAL_COMPLAINT_ESCALATED'
    form do
      field :customertitle, present: true
      field :customerforename, present: true
      field :customersurname, present: true
      field :customercontact, present: true
      field :eventtext, present: true
    end
  else
    form do
      field :eventtext, present: true
    end
  end

  if form.failed?

    actions    = []
    kase       = JSON.parse(RestClient.get("#{settings.protocol}://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}"))
    categories = JSON.parse(RestClient.get("#{settings.protocol}://#{settings.case_service_host}:#{settings.case_service_port}/categories"))
    erb :event, locals: { title: "Create Event for Case #{case_id}",
                          action: "/sampleunitref/#{sampleunitref}/cases/#{case_id}/event",
                          method: :post,
                          page: params[:page],
                          case_id: case_id,
                          eventtext: eventtext,
                          customertitle: customertitle,
                          customerforename: customerforename,
                          customersurname: customersurname,
                          customercontact: customercontact,
                          eventcategory: params[:eventcategory],
                          createdby: '',
                          categories: categories,
                          sampleunitref: sampleunitref }

  else
    user        = session[:user]
    description = params[:eventtext]
    description = "name: #{name.capitalize} #{description}" if !customerforename.empty? && customercontact.empty?
    description = "phone: #{customercontact} #{description}" if customerforename.empty? && !customercontact.empty?
    description = "name: #{name.capitalize} phone: #{customercontact} #{description}" if !customerforename.empty? && !customercontact.empty?

    RestClient.post("#{settings.protocol}://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}/events",
                    {
                      description: description,
                      category: params[:eventcategory],
                      subCategory: nil,
                      partyId: case_id,
                      createdBy: 'test user'
                    }.to_json, content_type: :json, accept: :json) do |post_response, _request, _result, &_block|
      if post_response.code == 201
        flash[:notice] = 'Successfully created event.'
        actions = []
      else
        logger.error post_response
        error_flash('Unable to create event', post_response)
      end
    end

    event_url = "/sampleunitref/#{sampleunitref}/cases/#{case_id}/events"
    event_url += "?page=#{params[:page]}" if params[:page].present?
    redirect event_url
  end
end
