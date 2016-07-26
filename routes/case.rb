require_relative '../lib/core_ext/nilclass'
require_relative '../lib/core_ext/string'

helpers do
  def format_postcode(postcode)
    postcode.upcase!
    return postcode if postcode.length == 8

    # Add a space before the inward code, which is always three characters long.
    "#{postcode[0, postcode.length - 3]} #{postcode[-3, 3]}"
  end

  def url_format(str)
    str.gsub(/\s+/, '').downcase
  end

  def user_role
    session[:user].groups.delete_if { |group| group == 'collect-users' }.first
  end
end

# Get all cases for the selected address.
get '/addresses/:uprn/cases' do |uprn|
  authenticate!
  cases = []

  RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/cases/uprn/#{uprn}") do |response, _request, _result, &_block|
    cases = JSON.parse(response).paginate(page: params[:page]) unless response.code == 204
  end

  if cases.any?
    cases.each do |kase|
      survey_id = kase['surveyId']
      sample_id = kase['sampleId']
      survey = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/surveys/#{survey_id}"))
      sample = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/samples/#{sample_id}"))
      kase['surveyDescription'] = survey['description']
      kase['name'] = sample['name']
    end
  end

  # Get the selected address details so they can be displayed for reference.
  address = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/addresses/#{uprn}"))
  coordinates = "#{address['latitude']},#{address['longitude']}"
  erb :cases, layout: :sidebar_layout, locals: { title: "Cases for Address #{uprn}",
                                                 uprn: uprn,
                                                 cases: cases,
                                                 address: address,
                                                 coordinates: coordinates,
                                                 postcode: format_postcode(address['postcode'])
                                               }
end

# Get a specific case.
get '/case/:case_id' do |case_id|
  authenticate!
  events    = []
  actions   = []
  kase      = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}"))
  uprn = kase['uprn']
  survey_id = kase['surveyId']
  sample_id = kase['sampleId']
  survey    = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/surveys/#{survey_id}"))
  sample    = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/samples/#{sample_id}"))

  RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}/events") do |response, _request, _result, &_block|
    events = JSON.parse(response).paginate(page: params[:page]) unless response.code == 204
  end

  RestClient.get("http://#{settings.action_service_host}:#{settings.action_service_port}/actions/case/#{case_id}") do |response, _request, _result, &_block|
    actions = JSON.parse(response) unless response.code == 204
  end

  address = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/addresses/#{uprn}"))
  coordinates = "#{address['latitude']},#{address['longitude']}"
  erb :case_events, layout: :sidebar_layout, locals: { title: "Event History for Case #{case_id}",
                                                       uprn: uprn,
                                                       case_id: case_id,
                                                       kase: kase,
                                                       events: events,
                                                       address: address,
                                                       coordinates: coordinates,
                                                       postcode: format_postcode(address['postcode']),
                                                       survey: survey,
                                                       sample: sample,
                                                       actions: actions
                                                     }
end

# Get all questionnaires for a specific case.
get '/cases/:case_id/questionnaires' do |case_id|
  authenticate!
  questionnaires = []
  kase = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}"))
  questionnaires = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/questionnaires/case/#{case_id}"))
  if kase.empty?
    erb :case_not_found, locals: { title: 'Case Not Found' }
  else
    address = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/addresses/#{kase['uprn']}"))
    coordinates = "#{address['latitude']},#{address['longitude']}"
    erb :questionnaires, layout: :sidebar_layout,
                         locals: { title: "Questionnaires for Case #{case_id}",
                                   uprn: address['uprn'],
                                   case_id: case_id,
                                   kase: kase,
                                   questionnaires: questionnaires,
                                   address: address,
                                   coordinates: coordinates,
                                   postcode: format_postcode(address['postcode'])
                                 }
  end
end

# Postcode search.
get '/postcodes/:postcode' do |postcode|
  authenticate!
  addresses  = []
  search_url = "http://#{settings.case_service_host}:#{settings.case_service_port}/addresses/postcode/#{postcode}"

  # CTPA-477 Need to URI encode the postcode search string.
  RestClient.get(URI.encode(search_url)) do |response, _request, _result, &_block|
    addresses = JSON.parse(response).paginate(page: params[:page]) unless response.code == 404
  end

  formatted_postcode = format_postcode(postcode)
  erb :addresses, locals: { title: "Addresses for Postcode #{formatted_postcode}",
                            addresses: addresses,
                            postcode: formatted_postcode }
end

# Present a form for creating a new event.
get '/case/:case_id/event/new' do |case_id|
  authenticate!
  categories = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/categories?role=#{user_role}"))
  erb :event, locals: { title: "Create Event for Case #{case_id}",
                        action: "/case/#{case_id}/event",
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

  form do
    field :eventtext, present: true
  end

  if form.failed?
    categories = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/categories?role=#{user_role}"))
    erb :event, locals: { title: "Create Event for Case #{case_id}",
                          action: "/case/#{case_id}/event",
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
    description = params[:eventtext]
    description = "name: #{name} #{description}" if !name.empty? && phone.empty?
    description = "phone: #{phone} #{description}" if name.empty? && !phone.empty?
    description = "name: #{name} phone: #{phone} #{description}" if !name.empty? && !phone.empty?

    RestClient.post("http://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}/events",
                    { description: description,
                      category: params[:eventcategory],
                      createdBy: user.user_id
                    }.to_json, content_type: :json, accept: :json
                   ) do |post_response, _request, _result, &_block|
      if post_response.code == 200
        flash[:notice] = 'Successfully created event.'
        actions = []

        if params[:eventcategory] == 'Closed' || params[:eventcategory] == 'IncorrectEscalation' || params[:eventcategory] == 'Undeliverable'
          RestClient.get("http://#{settings.action_service_host}:#{settings.action_service_port}/actions/case/#{case_id}") do |response, _request, _result, &_block|
            actions = JSON.parse(response).paginate(page: params[:page]) unless response.code == 204 # rubocop:disable Metrics/BlockNesting
          end
        end

        actions.each do |action|
          next unless action['actionTypeName'] == 'GeneralEscalation' || action['actionTypeName'] == 'SurveyEscalation' || action['actionTypeName'] == 'ComplaintEscalation'
          action_id = action['actionId']
          feedback_xml = <<-XML
            <p:actionFeedback xmlns:p="http://ons.gov.uk/ctp/response/action/message/feedback" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://ons.gov.uk/ctp/response/action/message/feedback actionFeedback.xsd">
              <actionId>#{action_id}</actionId>
              <situation></situation>
              <outcome>REQUEST_COMPLETED</outcome>
              <notes></notes>
            </p:actionFeedback>
          XML

          RestClient.put("http://#{settings.action_service_host}:#{settings.action_service_port}/actions/#{action_id}/feedback", feedback_xml, content_type: :xml) do |put_response, _request, _result, &_block|
            if put_response.code == 200
              logger.info 'Successfully completed action.'
            else
              logger.error put_response
              error_flash('Unable to complete action', put_response)
            end
          end
        end
      else
        logger.error post_response
        error_flash('Unable to create event', post_response)
      end
    end

    event_url = "/case/#{case_id}"
    event_url += "?page=#{params[:page]}" if params[:page].present?
    redirect event_url
  end
end
