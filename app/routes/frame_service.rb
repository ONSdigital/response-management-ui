module Beyond
  module Routes
    class FrameService < Base

      # Get all regions.
      get '/regions' do
        authenticate!
        regions = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/regions")).paginate(page: params[:page])
        erb :regions, locals: { title: 'Regions', regions: regions }
      end

      # Get all LAs for the selected region.
      get '/regions/:region_code/las' do |region_code|
        authenticate!
        local_authorities = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/regions/#{region_code}/lads")).paginate(page: params[:page])
        erb :local_authorities, locals: { title: "Local Authorities for Region #{region_code}",
                                          region_code: region_code,
                                          local_authorities: local_authorities }
      end

      # Get all msoas for the selected LA.
      get '/regions/:region_code/las/:local_authority_code/msoas' do |region_code, local_authority_code|
        authenticate!
        msoas = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/lads/#{local_authority_code}/msoas")).paginate(page: params[:page])
        erb :msoas, locals: { title: "MSOAs for LA #{local_authority_code}",
                              region_code: region_code,
                              local_authority_code: local_authority_code,
                              msoas: msoas }
      end

      # Get all addresses for the selected MSOA.
      get '/regions/:region_code/las/:local_authority_code/msoas/:msoa_code/addresses' do |region_code, local_authority_code, msoa_code|
        authenticate!
        addresses = []

        RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/msoas/#{msoa_code}/addresssummaries") do |response, _request, _result, &_block|
          addresses = JSON.parse(response).paginate(page: params[:page]) unless response.code == 204
        end

        erb :addresses, locals: { title: "Addresses for MSOA #{msoa_code}",
                                  region_code: region_code,
                                  local_authority_code: local_authority_code,
                                  msoa_code: msoa_code,
                                  addresses: addresses }

        #addresses = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/msoas/#{msoa_code}/addresssummaries")).paginate(page: params[:page])

      end

      # Get all the addresses to review for the selected msoa. -
      get '/regions/:region_code/las/:local_authority_code/msoas/:msoa_code/addresses/review' do |region_code, local_authority_code, msoa_code|
        authenticate!
        addresses = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/addresses?msoa11cd=#{msoa_code}&notestoreview=true")).paginate(page: params[:page])
        erb :review_addresses, locals: { title: "Review Addresses Notes for MSOA #{msoa_code}",
                                         region_code: region_code,
                                         local_authority_code: local_authority_code,
                                         msoa_code: msoa_code,
                                         addresses: addresses }
      end

      # Present a form for reviewing the address notes for an existing address.
      get '/regions/:region_code/las/:local_authority_code/msoas/:msoa_code/addresses/:uprn_code/review' do |region_code, local_authority_code, msoa_code, uprn_code|
        authenticate!
        addresses = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/addresses/#{uprn_code}"))
        address = addresses.first
        coordinates = "#{address['latitude']},#{address['longitude']}"
        follow_ups = JSON.parse(RestClient.get("http://#{settings.follow_up_service_host}:#{settings.follow_up_service_port}/FollowUpService/FollowUp/uprn=#{uprn_code}")).paginate(page: params[:page])
        action = "/regions/#{region_code}/las/#{local_authority_code}/msoas/#{msoa_code}/addresses/#{uprn_code}/review"

        erb :review_address, layout: :sidebar_layout,
                             locals: { title: "Review Address #{uprn_code} for MSOA #{msoa_code}",
                                       action: action,
                                       method: :put,
                                       page: params[:page],
                                       region_code: region_code,
                                       local_authority_code: local_authority_code,
                                       msoa_code: msoa_code,
                                       addresstype: address['type'],
                                       eastings: address['eastings'],
                                       northings: address['northings'],
                                       estabtype: address['estabtype'],
                                       hardtocount: address['htc'],
                                       address_line1: address['address_line1'].to_title_case,
                                       address_line2: address['address_line2'].to_title_case,
                                       town_name: address['town_name'].to_title_case,
                                       postcode: address['postcode'],
                                       oa11cd: address['oa11cd'],
                                       lsoa11cd: address['lsoa11cd'],
                                       coordinates: coordinates,
                                       follow_ups: follow_ups,
                                       uprn_code: address['uprn'] }
      end

=begin  Creation of Addresses is no longer valid until decisions on interaction with supplied address frame and unique uprn are understood

      # Present a form for creating a new address. -TODO
      get '/regions/:region_code/las/:local_authority_code/caseloads/:caseload_code/addresses/new' do |region_code, local_authority_code, caseload_code|
        authenticate!
        action = "/regions/#{region_code}/las/#{local_authority_code}/caseloads/#{caseload_code}/addresses"
        erb :address, locals: { title: "Create Address for Caseload #{caseload_code}",
                                action: action,
                                method: :post,
                                page: params[:page],
                                region_code: region_code,
                                local_authority_code: local_authority_code,
                                caseload_code: caseload_code,
                                addresstype: 'HH',
                                addgridref: '',
                                enumerationtype: '',
                                estabtype: '',
                                hardtocount: '1',
                                estabname: '',
                                namemanager: '',
                                buildingname: '',
                                subbuildingname: '',
                                buildingnumber: '',
                                thoroughfarename: '',
                                posttown: '',
                                postcode: '',
                                telnumber: '' }
      end

      # Create a new address. -TODO
      post '/regions/:region_code/las/:local_authority_code/caseloads/:caseload_code/addresses' do |region_code, local_authority_code, caseload_code|
        authenticate!
        if (params[:addresstype] == 'CE')
          form do
            filters :upcase
            field :addgridref, present: true, int: true, length: 13
            field :enumerationtype, present: true, int: true
            field :estabtype, present: true, int: true
            field :postcode, present: true
          end
        else
          form do
            filters :upcase
            field :addgridref, present: true, int: true, length: 13
            field :enumerationtype, present: true, int: true
            field :postcode, present: true
          end
        end

        if form.failed?
          action = "/regions/#{region_code}/las/#{local_authority_code}/caseloads/#{caseload_code}/addresses"
          output = erb :address, locals: { title: "Create Address for Caseload #{caseload_code}",
                                           action: action,
                                           method: :post,
                                           page: params[:page],
                                           region_code: region_code,
                                           local_authority_code: local_authority_code,
                                           caseload_code: caseload_code,
                                           addresstype: params[:addresstype],
                                           addgridref: params[:addgridref],
                                           enumerationtype: params[:enumerationtype],
                                           estabtype: params[:estabtype],
                                           hardtocount: params[:hardtocount],
                                           estabname: params[:estabname],
                                           namemanager: params[:namemanager],
                                           buildingname: params[:buildingname],
                                           subbuildingname: params[:subbuildingname],
                                           buildingnumber: params[:buildingnumber],
                                           thoroughfarename: params[:thoroughfarename],
                                           posttown: params[:posttown],
                                           postcode: params[:postcode],
                                           telnumber: params[:telnumber] }
          fill_in_form(output)
        else
          RestClient.post("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/addresses",
                          { addgridref: params[:addgridref],
                            addresstype: params[:addresstype],
                            buildingname: params[:buildingname],
                            buildingnumber: params[:buildingnumber],
                            caseload: caseload_code,
                            enumerationtype: params[:enumerationtype],
                            estabname: params[:estabname],
                            estabtype: params[:estabtype],
                            hardtocount: params[:hardtocount].to_i,
                            lad12cd: local_authority_code,
                            namemanager: params[:namemanager],
                            postcode: params[:postcode],
                            posttown: params[:posttown],
                            rgn11cd: region_code,
                            subbuildingname: params[:subbuildingname],
                            telnumber: params[:telnumber],
                            thoroughfarename: params[:thoroughfarename]
                          }.to_json, content_type: :json, accept: :json
                         ) do |response, _request, _result, &_block|
            if response.code == 200
              flash[:notice] = 'Successfully created address.'
            else
              flash[:error] = "Unable to create address (HTTP #{response.code} received)."
            end
          end

          addresses_url = "/regions/#{region_code}/las/#{local_authority_code}/caseloads/#{caseload_code}/addresses"
          addresses_url += "?page=#{params[:page]}" if params[:page].present?
          redirect addresses_url
        end
      end
=end

      # Present a form for editing an existing address.
      get '/regions/:region_code/las/:local_authority_code/msoas/:msoa_code/addresses/:uprn_code/edit' do |region_code, local_authority_code, msoa_code, uprn_code|
        authenticate!
        address = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/addresses/#{uprn_code}"))
        coordinates = "#{address['latitude']},#{address['longitude']}"
        action = "/regions/#{region_code}/las/#{local_authority_code}/msoas/#{msoa_code}/addresses/#{uprn_code}"

        erb :address, layout: :sidebar_layout,
                      locals: { title: "Edit Address #{uprn_code} for MSOA #{msoa_code}",
                                action: action,
                                method: :put,
                                page: params[:page],
                                address_line1: address['address_line1'].to_title_case,
                                address_line2: address['address_line2'].to_title_case,
                                addresstype: address['type'],
                                eastings: address['eastings'],
                                estabtype: address['estabtype'],
                                hardtocount: address['htc'],
                                local_authority_code: local_authority_code,
                                lsoa11cd: address['lsoa11cd'],
                                msoa_code: msoa_code,
                                northings: address['northings'],
                                oa11cd: address['oa11cd'],
                                postcode: address['postcode'],
                                region_code: region_code,
                                town_name: address['town_name'].to_title_case,
                                coordinates: coordinates }
      end

      # Update an existing address (either directly or by reviewing its address notes).
      ['/regions/:region_code/las/:local_authority_code/msoas/:msoa_code/addresses/:uprn_code',
       '/regions/:region_code/las/:local_authority_code/msoas/:msoa_code/addresses/:uprn_code/review'].each do |path|
        put path do
          authenticate!
          reviewing = path.end_with? 'review'

          if (params[:addresstype] == 'CE')
            form do
              filters :upcase
              field :address_line2, :present=>true
              field :eastings, :present=>true, :int=>true
              field :estabtype, :present=>true
              field :northings, :present=>true, :int=>true
              field :postcode, :present=>true
            end
          else
            form do
              filters :upcase
              field :address_line2, :present=>true
              field :addresstype, :present=>true
              field :eastings, :present=>true, :int=>true
              field :hardtocount, :present=>true
              field :northings, :present=>true, :int=>true
              field :postcode, :present=>true
            end
          end

          if form.failed?
            action = "/regions/#{params[:region_code]}/las/#{params[:local_authority_code]}/msoas/#{params[:msoa_code]}/addresses/#{params[:uprn_code]}"
            locals =  { method: :put,
                       page: params[:page],
                       address_line1: params[:address_line1],
                       address_line2: params[:address_line2],
                       addresstype: params[:addresstype],
                       eastings: params[:eastings],
                       estabtype: params[:estabtype],
                       hardtocount: params[:hardtocount],
                       local_authority_code: params[:local_authority_code],
                       lsoa11cd: params[:lsoa11cd],
                       msoa_code: params[:msoa_code],
                       northings: params[:northings],
                       oa11cd: params[:oa11cd],
                       postcode: params[:postcode],
                       region_code: params[:region_code],
                       town_name: params[:town_name] }

            if reviewing
              action += '/review'
              addresses = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/addresses/#{params[:uprn_code]}"))
              address = addresses.first
              coordinates = "#{address['latitude']},#{address['longitude']}"
              follow_ups = JSON.parse(RestClient.get("http://#{settings.follow_up_service_host}:#{settings.follow_up_service_port}/FollowUpService/FollowUp/uprn=#{params[:uprn_code]}")).paginate(page: params[:page])
              output = erb :review_address, layout: :sidebar_layout,
                                            locals: { title: "Review Address #{params[:uprn__code]} for MSOA #{params[:msoa_code]}",
                                                      action: action,
                                                      coordinates: coordinates,
                                                      follow_ups: follow_ups,
                                                      uprn_code: address['uprn_code'] }.merge(locals)
            else
              output = erb :address, locals: { title: "Edit Address for MSOA #{params[:msoa_code]}",
                                               action: action }.merge(locals)
            end

            fill_in_form(output)
          else
            RestClient.put("http://#{settings.frame_service_host}:#{settings.frame_service_port}/addresses/#{params[:uprn_code]}",
                           { addresstype: params[:addresstype],
                             estabtype: params[:estabtype],
                             msoa11cd: params[:msoa_code],
                             lsoa11cd: params[:lsoa11cd],
                             oa11cd: params[:oa11cd],
                             eastings: params[:eastings].to_i,
                             northings: params[:northings].to_i,
                             address_line1: params[:address_line1],
                             address_line2: params[:address_line2],
                             htc: params[:hardtocount].to_i,
                             lad12cd: params[:local_authority_code],
                             town_name: params[:town_name],
                             postcode: params[:postcode],
                             region11cd: params[:region_code],
                           }.to_json, content_type: :json, accept: :json
                          ) do |response, _request, _result, &_block|
              if response.code == 200
                flash[:notice] = 'Successfully updated address.'
              else
                flash[:error] = "Unable to update address (HTTP #{response.code} received)."
              end
            end

            addresses_url = "/regions/#{params[:region_code]}/las/#{params[:local_authority_code]}/msoas/#{params[:msoa_code]}/addresses"
            addresses_url += '/review' if reviewing
            addresses_url += "?page=#{params[:page]}" if params[:page].present?
            redirect addresses_url
          end
        end
      end

      # Get all cases for the selected address.
      get '/regions/:region_code/las/:local_authority_code/msoas/:msoa_code/addresses/:uprn_code/cases' do |region_code, local_authority_code, msoa_code, uprn_code|
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
                                       region_code: region_code,
                                       local_authority_code: local_authority_code,
                                       msoa_code: msoa_code,
                                       uprn_code: uprn_code,
                                       cases: cases,
                                       address: address,
                                       coordinates: coordinates
                                     }
      end

      # Get a specific case.
      get '/regions/:region_code/las/:local_authority_code/msoas/:msoa_code/case/:case_id' do |region_code, local_authority_code, msoa_code,case_id|
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
                                     region_code: address['code'],
                                     local_authority_code: address['ladCode'],
                                     msoa_code: address['msoaArea'],
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
                                     region_code: address['code'],
                                     local_authority_code: address['ladCode'],
                                     msoa_code: address['msoaArea'],
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
      get '/regions/:region_code/las/:local_authority_code/msoas/:msoa_code/cases/:case_id/questionnaires' do |region_code, local_authority_code, msoa_code,case_id|
        authenticate!
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
                                     region_code: address['code'],
                                     local_authority_code: address['ladCode'],
                                     msoa_code: address['msoaArea'],
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
                                     region_code: address['code'],
                                     local_authority_code: address['ladCode'],
                                     msoa_code: address['msoaArea'],
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

      # Present form after searching via postcode.
      get '/postcode/:postcode' do |postcode|
        authenticate!
        addresses = []

        RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/addresses/postcode/#{postcode}") do |response, _request, _result, &_block|
          addresses = JSON.parse(response).paginate(page: params[:page]) unless response.code == 404
        end

        erb :addresses_postcode, locals: { title: "Addresses for Postcode #{postcode}",
                                      addresses: addresses }

      end


      # Present a form for creating a new event.
      get '/regions/:region_code/las/:local_authority_code/msoas/:msoa_code/case/:case_id/event/new' do |region_code, local_authority_code, msoa_code, case_id|
      authenticate!
      action = "/regions/#{region_code}/las/#{local_authority_code}/msoas/#{msoa_code}/case/#{case_id}/event"

      # Get groups from session[:user].groups and remove the duplicated collect-user
      groups = session[:user].groups
      groups -= ['collect-users']

      categories = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/categories?role=#{groups.first}"))
      erb :event, locals: { title: "Create Event for Case #{case_id}",
                                    action: action,
                                    method: :post,
                                    page: params[:page],
                                    region_code: region_code,
                                    local_authority_code: local_authority_code,
                                    msoa_code: msoa_code,
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
      post '/regions/:region_code/las/:local_authority_code/msoas/:msoa_code/case/:case_id/event' do |region_code, local_authority_code, msoa_code, case_id|
        authenticate!

        #test for existence of description text
        form do
          field :eventtext, present: true
        end

        if form.failed?
          action = "/regions/#{region_code}/las/#{local_authority_code}/msoas/#{msoa_code}/case/#{case_id}/event"
          # Get groups from session[:user].groups and remove the duplicated collect-user
          groups = session[:user].groups
          groups -= ['collect-users']
          categories = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/categories?role=#{groups.first}"))
          erb :event, locals: { title: "Create Event for Case #{case_id}",
                                        action: action,
                                        method: :post,
                                        page: params[:page],
                                        region_code: region_code,
                                        local_authority_code: local_authority_code,
                                        msoa_code: msoa_code,
                                        eventtext: '',
                                        customername: '',
                                        customercontact: '',
                                        eventcategory: '',
                                        createdby: '',
                                        description_error: true,
                                        case_id: case_id,
                                        categories: categories
                                        }

        else
          user  = session[:user]
          name  = ''
          phone = ''

          name  = "name: #{params[:customername]} " unless params[:customername].length == 0
          phone = "phone: #{params[:customercontact]} " unless params[:customercontact].length == 0

          RestClient.post("http://#{settings.frame_service_host}:#{settings.frame_service_port}/cases/#{case_id}/events",
                          { description: "#{name} #{phone} #{params[:eventtext]}",
                            category: params[:eventcategory],
                            createdBy: "#{user.user_id}"
                          }.to_json, content_type: :json, accept: :json
                         ) do |response, _request, _result, &_block|
            if response.code == 200
              flash[:notice] = 'Successfully created event.'
            else
              flash[:error] = "Unable to create event (HTTP #{response.code} received)."
            end
          end

          event_url = "/regions/#{region_code}/las/#{local_authority_code}/msoas/#{msoa_code}/case/#{case_id}"
          event_url += "?page=#{params[:page]}" if params[:page].present?
          redirect event_url
        end
      end

      # Present a form for creating a new questionnaire.
      get '/regions/:region_code/las/:local_authority_code/msoas/:msoa_code/addresses/:uprn_code/cases/:case_id/questionnaires/new' do |region_code, local_authority_code, msoa_code, uprn_code, case_id|
        authenticate!
        action = "/regions/#{region_code}/las/#{local_authority_code}/msoas/#{msoa_code}/addresses/#{uprn_code}/questionnaires"
        erb :questionnaire, locals: { title: "Create Questionnaire for Address #{uprn_code}",
                                      action: action,
                                      method: :post,
                                      page: params[:page],
                                      region_code: region_code,
                                      local_authority_code: local_authority_code,
                                      msoa_code: msoa_code,
                                      case_id: case_id,
                                      uprn_code: uprn_code,
                                      formtype: '01',
                                      formstatus: 0 }
      end


      # Create a new questionnaire.
      post '/regions/:region_code/las/:local_authority_code/msoas/:msoa_code/addresses/:uprn_code/questionnaires' do |region_code, local_authority_code, msoa_code, uprn_code|
        authenticate!
        RestClient.post("http://#{settings.frame_service_host}:#{settings.frame_service_port}/#{params[:formtype]}/questionnaires",
                        { uprn: uprn_code,
                          formtype: params[:formtype],
                          formstatus: params[:formstatus].to_i
                        }.to_json, content_type: :json, accept: :json
                       ) do |response, _request, _result, &_block|
          if response.code == 200
            flash[:notice] = 'Successfully created questionnaire.'
          else
            flash[:error] = "Unable to create questionnaire (HTTP #{response.code} received)."
          end
        end

        questionnaires_url = "/regions/#{region_code}/las/#{local_authority_code}/msoas/#{msoa_code}/addresses/#{uprn_code}/questionnaires"
        questionnaires_url += "?page=#{params[:page]}" if params[:page].present?
        redirect questionnaires_url
      end

      # Present a form for editing an existing questionnaire.
      get '/regions/:region_code/las/:local_authority_code/msoas/:msoa_code/addresses/:uprn_code/case/:case_id/questionnaires/:questionnaire_id/iac/:iac/edit' do |region_code, local_authority_code, msoa_code, uprn_code, case_id, questionnaire_id, iac|
        authenticate!
        questionnaire = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/questionnaires/iac/#{iac}"))
        action = "/regions/#{region_code}/las/#{local_authority_code}/msoas/#{msoa_code}/addresses/#{uprn_code}/questionnaires/#{questionnaire_id}"

        erb :questionnaire, locals: { title: "Edit Questionnaire #{questionnaire_id} for Address #{uprn_code}",
                                      action: action,
                                      method: :put,
                                      page: params[:page],
                                      region_code: region_code,
                                      local_authority_code: local_authority_code,
                                      msoa_code: msoa_code,
                                      uprn_code: uprn_code,
                                      case_id: case_id,
                                      formtype: questionnaire['questionSet'],
                                      formstatus: questionnaire['questionnaireStatus'].to_i }
      end

      # Update an existing questionnaire
      put '/regions/:region_code/las/:local_authority_code/msoas/:msoa_code/addresses/:uprn_code/questionnaires/:questionnaire_id' do |region_code, local_authority_code, msoa_code, uprn_code, questionnaire_id|
        authenticate!
        RestClient.put("http://#{settings.frame_service_host}:#{settings.frame_service_port}/questionnaires/#{questionnaire_id}",
                       { uprn: uprn_code,
                         formtype: params[:formtype],
                         formstatus: params[:formstatus].to_i
                       }.to_json, content_type: :json, accept: :json
                      ) do |response, _request, _result, &_block|
          if response.code == 200
            flash[:notice] = 'Successfully updated questionnaire.'
          else
            flash[:error] = "Unable to update questionnaire (HTTP #{response.code} received)."
          end
        end

        questionnaires_url = "/regions/#{region_code}/las/#{local_authority_code}/msoas/#{msoa_code}/addresses/#{uprn_code}/questionnaires"
        questionnaires_url += "?page=#{params[:page]}" if params[:page].present?
        redirect questionnaires_url
      end
    end
  end
end
