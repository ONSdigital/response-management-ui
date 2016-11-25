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
  cases     = []
  casegroups = []
  casetype  = []
  sample_id = ''

  RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/casegroups/uprn/#{uprn}") do |response, _request, _result, &_block|
    casegroups = JSON.parse(response) unless response.code == 404 || response.code == 204
    casegroups.each do |casegroup|
      casegroup_id = casegroup['caseGroupId']

      RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/cases/casegroup/#{casegroup_id}") do |cases_response, _request, _result, &_block|
        cases = JSON.parse(cases_response).paginate(page: params[:page]) unless cases_response.code == 404
      end

      cases.each do |kase|
        sample_id   = casegroup['sampleId']
        sample      = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/samples/#{sample_id}"))
        casetype_id = kase['caseTypeId']
        casetype    = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/casetypes/#{casetype_id}"))
        contact     = kase['contact']
        #add extra values to the kase object
        kase['surveyDescription'] = sample['survey']
        kase['name']              = sample['name']
        kase['questionSet']       = casetype['questionSet']

        if !contact.nil?
          kase['contact']         = contact['forename'] +" "+ contact['surname']
        end
      end
    end
  end

  # Get the selected address details so they can be displayed for reference.
  address = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/addresses/#{uprn}"))
  erb :cases, layout: :sidebar_layout, locals: { title: "Cases for Address",
                                                 uprn: uprn,
                                                 sample_id: sample_id,
                                                 cases: cases,
                                                 address: address,
                                                 coordinates: coordinates_for(address),
                                                 postcode: format_postcode(address['postcode'])
                                               }
end

# Get a specific case.
get '/cases/:case_id/uprn/:uprn/sample/:sample_id?' do |case_id, uprn, sample_id|
  authenticate!
  events         = []
  actions        = []
  sample         = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/samples/#{sample_id}"))
  survey         = sample['survey']
  kase           = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}"))
  responses      = kase['responses']
  case_state     = kase['state']

  RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}/events") do |response, _request, _result, &_block|
    events     = JSON.parse(response).paginate(page: params[:page]) unless response.code == 204
    events.each do |event|
      category_name         = event['category']
      category              = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/categories/#{category_name}"))
      event['categoryName'] = category['longDescription']
    end
  end

  RestClient.get("http://#{settings.action_service_host}:#{settings.action_service_port}/actions/case/#{case_id}") do |response, _request, _result, &_block|
    actions = JSON.parse(response) unless response.code == 204
  end

  casetype_id     = kase['caseTypeId']
  casetype        = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/casetypes/#{casetype_id}"))
  question_set    = casetype['questionSet']
  address         = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/addresses/#{uprn}"))
  respondent_type = casetype['respondentType']

  paper            = false
  online           = false

  actionplanmappings = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/actionplanmappings/casetype/#{casetype_id}"))
  actionplanmappings.each do | actionplanmapping |
    if !actionplanmapping['isDefault']
      if actionplanmapping['inboundChannel'] == 'PAPER'
        paper  = true
      elsif actionplanmapping['inboundChannel'] == 'ONLINE'
        online = true
      end
    end
  end

  erb :case_events, layout: :sidebar_layout, locals: { title: "Event History for Case #{case_id}",
                                                       case_id: case_id,
                                                       kase: kase,
                                                       events: events,
                                                       address: address,
                                                       uprn: address['uprn'],
                                                       coordinates: coordinates_for(address),
                                                       postcode: format_postcode(address['postcode']),
                                                       survey: survey,
                                                       sample: sample,
                                                       sample_id: sample_id,
                                                       responses: responses,
                                                       actions: actions,
                                                       question_set: question_set,
                                                       respondent_type: respondent_type,
                                                       case_state: case_state,
                                                       paper: paper,
                                                       online: online
                                                     }
end

# Postcode search.
get '/postcodes/:postcode' do |postcode|
  authenticate!
  addresses  = []
  search_url = "http://#{settings.case_service_host}:#{settings.case_service_port}/addresses/postcode/#{postcode}"

  # CTPA-477 Need to URI encode the postcode search string.
  RestClient.get(URI.encode(search_url)) do |response, _request, _result, &_block|
    addresses = JSON.parse(response).paginate(page: params[:page]) unless response.code == 404 || response.code == 500
  end

  formatted_postcode = format_postcode(postcode)
  erb :addresses, locals: { title: "Addresses for Postcode #{formatted_postcode}",
                            addresses: addresses,
                            postcode: formatted_postcode }
end

# Present a form for creating a new event.
get '/cases/:case_id/uprn/:uprn/sample/:sample_id/event/new' do |case_id, uprn, sample_id|
  authenticate!
  kase       = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}"))
  address    = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/addresses/#{uprn}"))
  categories = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/categories?role=#{user_role}&group=general"))
  erb :event, locals: { title: "Create Event for Case #{case_id}",
                        action: "/cases/#{case_id}/uprn/#{uprn}/sample/#{sample_id}/event",
                        method: :post,
                        page: params[:page],
                        uprn: address['uprn'],
                        case_id: case_id,
                        postcode: format_postcode(address['postcode']),
                        eventtext: '',
                        customertitle: '',
                        customerforename: '',
                        customersurname: '',
                        customercontact: '',
                        eventcategory: '',
                        createdby: '',
                        sample_id: sample_id,
                        categories: categories
                      }
end

# Create a new event.
post '/cases/:case_id/uprn/:uprn/sample/:sample_id/event' do |case_id, uprn, sample_id|
  authenticate!

  form do
    field :eventtext, present: true
  end

  customertitle    = params[:customertitle]
  customerforename = params[:customerforename]
  customersurname  = params[:customersurname]
  name             = params[:customertitle] + ' ' + params[:customerforename] + ' ' + params[:customersurname]
  phone            = params[:customercontact]

  if form.failed?
    kase       = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}"))
    address    = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/addresses/#{uprn}"))
    categories = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/categories?role=#{user_role}&group=general"))
    uprn       = address['uprn']
    erb :event, locals: { title: "Create Event for Case #{case_id}",
                          action: "/cases/#{case_id}/uprn/#{uprn}/sample/#{sample_id}/event",
                          method: :post,
                          page: params[:page],
                          uprn: uprn,
                          case_id: case_id,
                          postcode: format_postcode(address['postcode']),
                          eventtext: '',
                          customertitle: customertitle,
                          customerforename: customerforename,
                          customersurname: customersurname,
                          customercontact: phone,
                          eventcategory: params[:eventcategory],
                          createdby: '',
                          sample_id: sample_id,
                          categories: categories
                        }
  else
    user        = session[:user]
    description = params[:eventtext]
    description = "name: #{name.capitalize} #{description}" if !customerforename.empty? && phone.empty?
    description = "phone: #{phone} #{description}" if customerforename.empty? && !phone.empty?
    description = "name: #{name.capitalize} phone: #{phone} #{description}" if !customerforename.empty? && !phone.empty?

    RestClient.post("http://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}/events",
                    { description: description,
                      category: params[:eventcategory],
                      createdBy: user.user_id
                    }.to_json, content_type: :json, accept: :json
                   ) do |post_response, _request, _result, &_block|
      if post_response.code == 200
        flash[:notice] = 'Successfully created event.'
        actions = []

        if params[:eventcategory] == 'INCORRECT_ESCALATION' || params[:eventcategory] == 'REFUSAL' || params[:eventcategory] == 'CLOSE_ESCALATION'
          RestClient.get("http://#{settings.action_service_host}:#{settings.action_service_port}/actions/case/#{case_id}") do |response, _request, _result, &_block|
            actions = JSON.parse(response).paginate(page: params[:page]) unless response.code == 204 # rubocop:disable Metrics/BlockNesting
          end
        end

        actions.each do |action|
          next unless action['actionTypeName'] == 'GE_ESCALATION' || action['actionTypeName'] == 'GC_ESCALATION' || action['actionTypeName'] == 'FE_ESCALATION' || action['actionTypeName'] == 'FC_ESCALATION'
          if action['state'] == 'PENDING'
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
        end
      else
        logger.error post_response
        error_flash('Unable to create event', post_response)
      end
    end

    event_url = "/cases/#{case_id}/uprn/#{uprn}/sample/#{sample_id}"
    event_url += "?page=#{params[:page]}" if params[:page].present?
    redirect event_url
  end
end

# Present a form for requesting a translation booklet.
get '/cases/:case_id/uprn/:uprn/sample/:sample_id/translate/new' do |case_id, uprn, sample_id|
  authenticate!
  kase       = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}"))
  address    = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/addresses/#{uprn}"))
  products   = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/categories?group=translation"))
  erb :translate, locals: { title: "Request Translation Booklet for Case #{case_id}",
                        action: "/cases/#{case_id}/uprn/#{uprn}/sample/#{sample_id}/translate",
                        method: :post,
                        page: params[:page],
                        uprn: address['uprn'],
                        case_id: case_id,
                        postcode: format_postcode(address['postcode']),
                        eventtext: '',
                        customertitle: '',
                        customerforename: '',
                        customersurname: '',
                        eventcategory: '',
                        createdby: '',
                        address: address,
                        sample_id: sample_id,
                        products: products
                      }
end

# Request a translation booklet and create associated event.
post '/cases/:case_id/uprn/:uprn/sample/:sample_id/translate' do |case_id, uprn, sample_id|
  authenticate!

  form do
    field :customertitle, present: true
    field :customerforename, present: true
    field :customersurname, present: true
  end

  customertitle       = params[:customertitle]
  customerforename    = params[:customerforename]
  customersurname     = params[:customersurname]
  event_category      = params[:eventcategory]

  if form.failed?
    kase         = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}"))
    address      = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/addresses/#{uprn}"))
    products     = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/categories?group=translation"))

    erb :translate, locals: { title: "Request Translation Booklet for Case #{case_id}",
                          action: "/cases/#{case_id}/uprn/#{uprn}/sample/#{sample_id}/translate",
                          method: :post,
                          page: params[:page],
                          uprn: uprn,
                          case_id: case_id,
                          postcode: format_postcode(address['postcode']),
                          eventtext: '',
                          customertitle: customertitle,
                          customerforename: customerforename,
                          customersurname: customersurname,
                          eventcategory: event_category,
                          createdby: '',
                          address: address,
                          sample_id: sample_id,
                          products: products
                        }
  else
    user           = session[:user]
    category       = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/categories/#{event_category}"))
    language       = category['shortDescription']
    description    = "Translation Booklet in #{language} supplied to "
    description    = "#{description} #{customertitle.capitalize} #{customerforename} #{customersurname}"

    RestClient.post("http://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}/events",
                    { description: description,
                      category: event_category,
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

    event_url = "/cases/#{case_id}/uprn/#{uprn}/sample/#{sample_id}"
    event_url += "?page=#{params[:page]}" if params[:page].present?
    redirect event_url
  end
end


# Present a form for paper/iac/post requests.
get '/cases/:case_id/uprn/:uprn/sample/:sample_id/request/:type/new' do |case_id, uprn, sample_id, type|
  authenticate!

  if type == 'individual'
    title = "Request Individual Form for Case #{case_id}"
  elsif type == 'paper'
    title = "Request Paper Questionnaire for Case #{case_id}"
  elsif type == 'iac'
    title = "Request Replacement IAC for Case #{case_id}"
  end

  sample_case_types = []
  casetype_id = ''
  kase        = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}"))

  if type == 'individual'
    casegroup_id      = kase['caseGroupId']
    casegroup         = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/casegroups/#{casegroup_id}"))
    sample_id         = casegroup['sampleId']
    sample            = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/samples/#{sample_id}"))
    sample_case_types = sample['sampleCaseTypes']

    puts "sample_case_types #{sample_case_types}"

    sample_case_types.each do | sample_case_type |
      if sample_case_type['respondentType'] == 'HI'
        casetype_id = sample_case_type['caseTypeId']
      end
    end
  else
    casetype_id = kase['caseTypeId']
  end


  puts "case #{kase}"
  puts "casetype_id #{casetype_id}"

  address            = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/addresses/#{uprn}"))
  actionplanmappings = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/actionplanmappings/casetype/#{casetype_id}"))
  erb :newcase, locals: { title: title,
                            action: "/cases/#{case_id}/uprn/#{uprn}/sample/#{sample_id}/#{type}",
                            method: :post,
                            page: params[:page],
                            uprn: address['uprn'],
                            case_id: case_id,
                            postcode: format_postcode(address['postcode']),
                            eventtext: '',
                            customertitle: '',
                            customerforename: '',
                            customersurname: '',
                            eventcategory: '',
                            createdby: '',
                            sample_id: sample_id,
                            address: address,
                            actionplanmappings: actionplanmappings,
                            phonenumber: '',
                            actionplanmappingid: '',
                            type: type
                          }
end


# Request creation of new case for paper/iac/individual cases and create associated event.
post '/cases/:case_id/uprn/:uprn/sample/:sample_id/:type' do |case_id, uprn, sample_id, type|
  authenticate!
  actionplanmappingid = params[:actionplanradio]
  if !actionplanmappingid.nil?
    actionplanmapping = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/actionplanmappings/#{actionplanmappingid}"))
    outboundchannel   = actionplanmapping['outboundChannel']
  end

  customertitle     = params[:customertitle]
  customerforename  = params[:customerforename]
  customersurname   = params[:customersurname]
  phonenumber       = params[:phonenumber]
  phoneregex        = /^$|\d{11}/

  phonematch        = phoneregex.match(phonenumber)

  form do
    field :actionplanradio, present: true
    field :customertitle, present: true
    field :customerforename, present: true
    field :customersurname, present: true
    field :phonenumber, present: true, regexp: %r{^$|\d{11}} if outboundchannel == 'SMS'
  end

  if type == 'individual'
    title = "Request Individual Form for Case #{case_id}"
  elsif type == 'paper'
    title = "Request Paper Questionnaire for Case #{case_id}"
  elsif type == 'iac'
    title = "Request Replacement IAC for Case #{case_id}"
  end

  if form.failed?
    sample_case_types = []
    casetype_id = ''
    kase        = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}"))

    if type == 'individual'
      casegroup_id      = kase['caseGroupId']
      casegroup         = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/casegroups/#{casegroup_id}"))
      sample_id         = casegroup['sampleId']
      sample            = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/samples/#{sample_id}"))
      sample_case_types = sample['sampleCaseTypes']

      puts "sample_case_types #{sample_case_types}"

      sample_case_types.each do | sample_case_type |
        if sample_case_type['respondentType'] == 'HI'
          casetype_id = sample_case_type['caseTypeId']
        end
      end
    else
      casetype_id = kase['caseTypeId']
    end


    puts "case #{kase}"
    puts "casetype_id #{casetype_id}"

    address            = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/addresses/#{uprn}"))
    actionplanmappings = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/actionplanmappings/casetype/#{casetype_id}"))

    erb :newcase, locals: { title: title,
                              action: "/cases/#{case_id}/uprn/#{uprn}/sample/#{sample_id}/#{type}",
                              method: :post,
                              page: params[:page],
                              uprn: address['uprn'],
                              case_id: case_id,
                              postcode: format_postcode(address['postcode']),
                              eventtext: '',
                              customertitle: customertitle,
                              customerforename: customerforename,
                              customersurname: customersurname,
                              eventcategory: '',
                              createdby: '',
                              sample_id: sample_id,
                              address: address,
                              actionplanmappings: actionplanmappings,
                              phonenumber: phonenumber,
                              actionplanmappingid: actionplanmappingid,
                              type: type
                            }
  else
    user        = session[:user]
    if type    == 'individual'
      description = "Individual Form sent to"
    elsif type == 'paper'
      description = "Paper Questionnaire sent to"
    elsif type == 'iac'
      description = "Replacement IAC sent to"
    end
    description = "#{description} #{customertitle.capitalize} #{customerforename} #{customersurname}"

    sample_case_types = []
    casetype_id = ''
    kase        = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}"))

    if type == 'individual'
      casegroup_id      = kase['caseGroupId']
      casegroup         = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/casegroups/#{casegroup_id}"))
      sample_id         = casegroup['sampleId']
      sample            = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/samples/#{sample_id}"))
      sample_case_types = sample['sampleCaseTypes']

      puts "sample_case_types #{sample_case_types}"

      sample_case_types.each do | sample_case_type |
        if sample_case_type['respondentType'] == 'HI'
          casetype_id = sample_case_type['caseTypeId']
        end
      end
    else
      casetype_id = kase['caseTypeId']
    end


    puts "case #{kase}"
    puts "casetype_id #{casetype_id}"

    casetype        = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/casetypes/#{casetype_id}"))
    question_set    = casetype['questionSet']
    respondent_type = casetype['respondentType']

    if type == 'individual'
      event_category = 'INDIVIDUAL_RESPONSE_REQUESTED'
    elsif type == 'paper'
      if respondent_type == 'H'
        event_category = 'HOUSEHOLD_PAPER_REQUESTED'
      elsif respondent_type == 'HI'
        event_category = 'INDIVIDUAL_PAPER_REQUESTED'
      end
    elsif type == 'iac'
      if respondent_type == 'H'
        event_category = 'HOUSEHOLD_REPLACEMENT_IAC_REQUESTED'
      elsif respondent_type == 'HI'
        event_category = 'INDIVIDUAL_REPLACEMENT_IAC_REQUESTED'
      end
    end
    case_group_id  = kase['caseGroupId']

    RestClient.post("http://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}/events",
                    { description: description,
                      category: event_category,
                      createdBy: user.user_id,
                      caseCreationRequest: {
                                              caseTypeId: casetype_id,
                                              actionPlanMappingId: actionplanmappingid,
                                              title: customertitle,
                                              forename: customerforename,
                                              surname: customersurname,
                                              phoneNumber: phonenumber
                                            }
                    }.to_json, content_type: :json, accept: :json
                   ) do |post_response, _request, _result, &_block|
      if post_response.code == 200
        flash[:notice] = 'Successfully created event.'
      else
        logger.error post_response
        error_flash('Unable to create event', post_response)
      end
    end

    event_url = "/cases/#{case_id}/uprn/#{uprn}/sample/#{sample_id}"
    event_url += "?page=#{params[:page]}" if params[:page].present?
    redirect event_url
  end
end
