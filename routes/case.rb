require_relative '../lib/core_ext/nilclass'
require_relative '../lib/core_ext/string'

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

  def user_role
    session[:user].groups.delete_if { |group| group == 'collect-users' }.first
  end
end

# Get all cases for the selected address.
get '/addresses/:uprn/cases/?' do |uprn|
  authenticate!
  cases = []

  RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/cases/uprn/#{uprn}") do |response, _request, _result, &_block|
    cases = JSON.parse(response).paginate(page: params[:page]) unless response.code == 204
  end

  cases.each do |kase|
    survey_id = kase['surveyId']
    sample_id = kase['sampleId']
    survey = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/surveys/#{survey_id}"))
    sample = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/samples/#{sample_id}"))
    kase['surveyDescription'] = survey['description']
    kase['name'] = sample['name']
  end

  # Get the selected address details so they can be displayed for reference.
  address = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/addresses/#{uprn}"))
  erb :cases, layout: :sidebar_layout, locals: { title: "Cases for Address #{uprn}",
                                                 uprn: uprn,
                                                 cases: cases,
                                                 address: address,
                                                 coordinates: coordinates_for(address),
                                                 postcode: format_postcode(address['postcode'])
                                               }
end

# Get a specific case.
get '/cases/:case_id/?' do |case_id|
  authenticate!
  events    = []
  actions   = []
  kase      = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}"))
  uprn = kase['uprn']
  survey_id = kase['surveyId']
  sample_id = kase['sampleId']
  survey    = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/surveys/#{survey_id}"))
  sample    = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/samples/#{sample_id}"))
  questionnaires = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/questionnaires/case/#{case_id}"))

  RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}/events") do |response, _request, _result, &_block|
    events = JSON.parse(response).paginate(page: params[:page]) unless response.code == 204
  end

  RestClient.get("http://#{settings.action_service_host}:#{settings.action_service_port}/actions/case/#{case_id}") do |response, _request, _result, &_block|
    actions = JSON.parse(response) unless response.code == 204
  end

  address = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/addresses/#{uprn}"))
  erb :case_events, layout: :sidebar_layout, locals: { title: "Event History for Case #{case_id}",
                                                       uprn: uprn,
                                                       case_id: case_id,
                                                       kase: kase,
                                                       events: events,
                                                       address: address,
                                                       coordinates: coordinates_for(address),
                                                       postcode: format_postcode(address['postcode']),
                                                       survey: survey,
                                                       sample: sample,
                                                       questionnaires: questionnaires,
                                                       actions: actions
                                                     }
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
get '/cases/:case_id/event/new' do |case_id|
  authenticate!
  kase       = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}"))
  address    = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/addresses/#{kase['uprn']}"))
  categories = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/categories?role=#{user_role}"))
  erb :event, locals: { title: "Create Event for Case #{case_id}",
                        action: "/cases/#{case_id}/event",
                        method: :post,
                        page: params[:page],
                        uprn: address['uprn'],
                        case_id: case_id,
                        postcode: format_postcode(address['postcode']),
                        eventtext: '',
                        customername: '',
                        customercontact: '',
                        eventcategory: '',
                        createdby: '',
                        categories: categories
                      }
end

# Create a new event.
post '/cases/:case_id/event' do |case_id|
  authenticate!

  form do
    field :eventtext, present: true
  end

  name  = params[:customername]
  phone = params[:customercontact]

  if form.failed?
    kase       = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}"))
    address    = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/addresses/#{kase['uprn']}"))
    categories = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/categories?role=#{user_role}"))
    erb :event, locals: { title: "Create Event for Case #{case_id}",
                          action: "/cases/#{case_id}/event",
                          method: :post,
                          page: params[:page],
                          uprn: address['uprn'],
                          case_id: case_id,
                          postcode: format_postcode(address['postcode']),
                          eventtext: '',
                          customername: name,
                          customercontact: phone,
                          eventcategory: params[:eventcategory],
                          createdby: '',
                          categories: categories
                        }
  else
    user        = session[:user]
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

    event_url = "/cases/#{case_id}"
    event_url += "?page=#{params[:page]}" if params[:page].present?
    redirect event_url
  end
end

# Present a form for requesting an indvidual form.
get '/cases/:case_id/childcase/new' do |case_id|
  authenticate!
  kase       = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}"))
  address    = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/addresses/#{case_id}"))
  erb :childcase, locals: { title: "Request Individual Form for Case #{case_id}",
                            action: "/cases/#{case_id}/childcase",
                            method: :post,
                            page: params[:page],
                            uprn: address['uprn'],
                            case_id: case_id,
                            postcode: format_postcode(address['postcode']),
                            eventtext: '',
                            customername: '',
                            customeremail: '',
                            customercontact: '',
                            eventcategory: '',
                            createdby: '',
                            address: address
                          }
end

# Request creation of childcase (individual form) and create associated event.
post '/cases/:case_id/childcase' do |case_id|
  authenticate!

  form do
    field :customername, present: true
  end

  name  = params[:customername]
  phone = params[:customercontact]
  email = params[:customeremail]

  if form.failed?
    kase       = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}"))
    address    = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/addresses/#{case_id}"))
    erb :childcase, locals: { title: "Request Individual Form for Case #{case_id}",
                              action: "/cases/#{case_id}/childcase",
                              method: :post,
                              page: params[:page],
                              uprn: address['uprn'],
                              case_id: case_id,
                              postcode: format_postcode(address['postcode']),
                              eventtext: '',
                              customername: '',
                              customeremail: '',
                              customercontact: '',
                              eventcategory: '',
                              createdby: '',
                              address: address
                            }
  else
    user        = session[:user]
    description = 'Individual form sent to '
    description = "#{description} name: #{name} email #{email} " if !name.empty? && !email.empty? && phone.empty?
    description = "#{description} name: #{name} email #{email} phone: #{phone} " if !name.empty? && !email.empty? && !phone.empty?

    # insert code to call end point for requesting individual form

    RestClient.post("http://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}/events",
                    { description: description,
                      category: params[:eventcategory],
                      createdBy: user.user_id
                    }.to_json, content_type: :json, accept: :json
                   ) do |post_response, _request, _result, &_block|
      if post_response.code == 200
        flash[:notice] = 'Successfully created event.'
      else
        logger.error post_response
        error_flash('Unable to create event', post_response)
      end
    end

    event_url = "/cases/#{case_id}"
    event_url += "?page=#{params[:page]}" if params[:page].present?
    redirect event_url
  end
end

# Present a form for requesting a paper form.
get '/cases/:case_id/paper/new' do |case_id|
  authenticate!
  kase       = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}"))
  address    = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/addresses/#{kase['uprn']}"))
  erb :paper, locals: { title: "Request Paper Questionnaire for Case #{case_id}",
                        action: "/cases/#{case_id}/paper",
                        method: :post,
                        page: params[:page],
                        uprn: address['uprn'],
                        case_id: case_id,
                        postcode: format_postcode(address['postcode']),
                        eventtext: '',
                        customername: '',
                        customercontact: '',
                        eventcategory: '',
                        createdby: '',
                        address: address
                      }
end

# Request printed questionnaire and create associated event.
post '/cases/:case_id/paper' do |case_id|
  authenticate!

  form do
    field :customername, present: true
  end

  name  = params[:customername]
  phone = params[:customercontact]

  if form.failed?
    kase       = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}"))
    address    = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/addresses/#{kase['uprn']}"))
    erb :paper, locals: { title: "Request Individual Form for Case #{case_id}",
                          action: "/cases/#{case_id}/paper",
                          method: :post,
                          page: params[:page],
                          uprn: address['uprn'],
                          case_id: case_id,
                          postcode: format_postcode(address['postcode']),
                          eventtext: '',
                          customername: '',
                          customercontact: '',
                          eventcategory: '',
                          createdby: '',
                          address: address
                        }
  else
    user        = session[:user]
    description = 'Printed Questionnaire sent to '
    description = "#{description} name: #{name} " if !name.empty? && phone.empty?
    description = "#{description} name: #{name} phone: #{phone} " if !name.empty? && !phone.empty?

    # insert code to call end point for requesting printed questionnaire

    RestClient.post("http://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}/events",
                    { description: description,
                      category: params[:eventcategory],
                      createdBy: user.user_id
                    }.to_json, content_type: :json, accept: :json
                   ) do |post_response, _request, _result, &_block|
      if post_response.code == 200
        flash[:notice] = 'Successfully created event.'
      else
        logger.error post_response
        error_flash('Unable to create event', post_response)
      end
    end

    event_url = "/cases/#{case_id}"
    event_url += "?page=#{params[:page]}" if params[:page].present?
    redirect event_url
  end
end

# Present a form for requesting a replacement IAC.
get '/cases/:case_id/iac/new' do |case_id|
  authenticate!
  kase       = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}"))
  address    = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/addresses/#{kase['uprn']}"))
  erb :iac, locals: { title: "Request Replacement IAC for Case #{case_id}",
                        action: "/cases/#{case_id}/iac",
                        method: :post,
                        page: params[:page],
                        uprn: address['uprn'],
                        case_id: case_id,
                        postcode: format_postcode(address['postcode']),
                        eventtext: '',
                        customername: '',
                        customeremail: '',
                        customercontact: '',
                        eventcategory: '',
                        createdby: '',
                        address: address
                      }
end

# Request new IAC and create associated event.
post '/cases/:case_id/iac' do |case_id|
  authenticate!

  form do
    field :customername, present: true
  end

  name  = params[:customername]
  phone = params[:customercontact]
  email = params[:customeremail]

  if form.failed?
    kase       = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}"))
    address    = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/addresses/#{kase['uprn']}"))
    erb :iac, locals: { title: "Request Individual Form for Case #{case_id}",
                          action: "/cases/#{case_id}/iac",
                          method: :post,
                          page: params[:page],
                          uprn: address['uprn'],
                          case_id: case_id,
                          postcode: format_postcode(address['postcode']),
                          eventtext: '',
                          customername: '',
                          customeremail: '',
                          customercontact: '',
                          eventcategory: '',
                          createdby: '',
                          address: address
                        }
  else
    user        = session[:user]
    description = 'New Internet Access Code requested for '
    description = "#{description} name: #{name} email #{email} " if !name.empty? && !email.empty? && phone.empty?
    description = "#{description} name: #{name} email #{email} phone: #{phone} " if !name.empty? && !email.empty? && !phone.empty?

    # insert code to call end point for requesting replacement IAC

    RestClient.post("http://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}/events",
                    { description: description,
                      category: params[:eventcategory],
                      createdBy: user.user_id
                    }.to_json, content_type: :json, accept: :json
                   ) do |post_response, _request, _result, &_block|
      if post_response.code == 200
        flash[:notice] = 'Successfully created event.'
      else
        logger.error post_response
        error_flash('Unable to create event', post_response)
      end
    end

    event_url = "/cases/#{case_id}"
    event_url += "?page=#{params[:page]}" if params[:page].present?
    redirect event_url
  end
end

# Present a form for requesting a translation booklet.
get '/cases/:case_id/translate/new' do |case_id|
  authenticate!
  kase       = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}"))
  address    = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/addresses/#{kase['uprn']}"))
  products   = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/products?role=#{user_role}"))
  erb :translate, locals: { title: "Request Translation Booklet for Case #{case_id}",
                        action: "/cases/#{case_id}/translate",
                        method: :post,
                        page: params[:page],
                        uprn: address['uprn'],
                        case_id: case_id,
                        postcode: format_postcode(address['postcode']),
                        eventtext: '',
                        customername: '',
                        customercontact: '',
                        eventcategory: '',
                        createdby: '',
                        address: address,
                        products: products
                      }
end

# Request a translation booklet and create associated event.
post '/cases/:case_id/translate' do |case_id|
  authenticate!

  form do
    field :customername, present: true
  end

  name  = params[:customername]
  phone = params[:customercontact]

  if form.failed?
    kase       = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}"))
    address    = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/addresses/#{kase['uprn']}"))
    products = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/products?role=#{user_role}"))
    erb :translate, locals: { title: "Request Translation Booklet for Case #{case_id}",
                          action: "/cases/#{case_id}/translate",
                          method: :post,
                          page: params[:page],
                          uprn: address['uprn'],
                          case_id: case_id,
                          postcode: format_postcode(address['postcode']),
                          eventtext: '',
                          customername: name,
                          customercontact: phone,
                          eventcategory: params[:eventcategory],
                          createdby: '',
                          address: address,
                          products: products
                        }
  else
    user        = session[:user]
    translation = params[:product]

    description = "Translation Booklet in #{translation} supplied to"
    description = "name: #{name} #{description}" if !name.empty? && phone.empty?
    description = "phone: #{phone} #{description}" if name.empty? && !phone.empty?
    description = "name: #{name} phone: #{phone} #{description}" if !name.empty? && !phone.empty?

    # insert code to call end point for requesting replacement IAC

    RestClient.post("http://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}/events",
                    { description: description,
                      category: params[:eventcategory],
                      createdBy: user.user_id
                    }.to_json, content_type: :json, accept: :json
                   ) do |post_response, _request, _result, &_block|
      if post_response.code == 200
        flash[:notice] = 'Successfully created event.'
      else
        logger.error post_response
        error_flash('Unable to create event', post_response)
      end
    end

    event_url = "/cases/#{case_id}"
    event_url += "?page=#{params[:page]}" if params[:page].present?
    redirect event_url
  end
end
