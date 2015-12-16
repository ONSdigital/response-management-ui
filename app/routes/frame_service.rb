module Beyond
  module Routes
    class FrameService < Base

      # Get all regions.
      get '/regions/?' do
        regions = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/regions")).paginate(page: params[:page])
        erb :regions, locals: { title: 'Regions', regions: regions }
      end

      # Get all LAs for the selected region.
      get '/regions/:region_code/las/?' do |region_code|
        local_authorities = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/lads?regionid=#{region_code}")).paginate(page: params[:page])
        erb :local_authorities, locals: { title: "Local Authorities for Region #{region_code}",
                                          region_code: region_code,
                                          local_authorities: local_authorities }
      end

      # Get all msoas for the selected LA.
      get '/regions/:region_code/las/:local_authority_code/msoas' do |region_code, local_authority_code|
        msoas = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/msoas?ladid=#{local_authority_code}")).paginate(page: params[:page])
        erb :msoas, locals: { title: "MSOAs for LA #{local_authority_code}",
                                  region_code: region_code,
                                  local_authority_code: local_authority_code,
                                  msoas: msoas }
      end

      # Get all addresses for the selected MSOA.
      get '/regions/:region_code/las/:local_authority_code/msoas/:msoa_code/addresses' do |region_code, local_authority_code, msoa_code|
        addresses = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/addresses?msoa11cd=#{msoa_code}")).paginate(page: params[:page])
        erb :addresses, locals: { title: "Addresses for MSOA #{msoa_code}",
                                  region_code: region_code,
                                  local_authority_code: local_authority_code,
                                  msoa_code: msoa_code,
                                  addresses: addresses }
      end

      # Get all the addresses to review for the selected msoa. -
      get '/regions/:region_code/las/:local_authority_code/msoas/:msoa_code/addresses/review' do |region_code, local_authority_code, msoa_code|
        addresses = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/addresses?msoa11cd=#{msoa_code}&notestoreview=true")).paginate(page: params[:page])
        erb :review_addresses, locals: { title: "Review Addresses Notes for MSOA #{msoa_code}",
                                         region_code: region_code,
                                         local_authority_code: local_authority_code,
                                         msoa_code: msoa_code,
                                         addresses: addresses }
      end

      # Present a form for reviewing the address notes for an existing address.
      get '/regions/:region_code/las/:local_authority_code/msoas/:msoa_code/addresses/:uprn_code/review' do |region_code, local_authority_code, msoa_code, uprn_code|
        addresses = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/addresses/#{uprn_code}"))
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
                                       addresstype: address['addresstype'],
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
        addresses = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/addresses/#{uprn_code}"))
        address = addresses.first
        coordinates = "#{address['latitude']},#{address['longitude']}"
        action = "/regions/#{region_code}/las/#{local_authority_code}/msoas/#{msoa_code}/addresses/#{uprn_code}"

        erb :address, layout: :sidebar_layout,
                      locals: { title: "Edit Address #{uprn_code} for MSOA #{msoa_code}",
                                action: action,
                                method: :put,
                                page: params[:page],
                                address_line1: address['address_line1'].to_title_case,
                                address_line2: address['address_line2'].to_title_case,
                                addresstype: address['addresstype'],
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
              addresses = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/addresses/#{params[:uprn_code]}"))
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
            RestClient.put("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/addresses/#{params[:uprn_code]}",
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

      # Get all questionnaires for the selected address.
      get '/regions/:region_code/las/:local_authority_code/msoas/:msoa_code/addresses/:uprn_code/questionnaires' do |region_code, local_authority_code, msoa_code, uprn_code|
        questionnaires = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/questionnaires?uprn=#{uprn_code}")).paginate(page: params[:page])

        # Get the selected address details so they can be redisplayed for reference.
        addresses = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/addresses/#{uprn_code}"))
        coordinates = "#{addresses.first['latitude']},#{addresses.first['longitude']}"
        erb :questionnaires, layout: :sidebar_layout,
                             locals: { title: "Questionnaires for Address #{uprn_code}",
                                       region_code: region_code,
                                       local_authority_code: local_authority_code,
                                       msoa_code: msoa_code,
                                       uprn_code: uprn_code,
                                       questionnaires: questionnaires,
                                       addresses: addresses,
                                       coordinates: coordinates }
      end

      # Get a specific questionnaire.
      get '/questionnaires/:questionnaire_id' do |questionnaire_id|
        questionnaires = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/questionnaires/#{questionnaire_id}"))

        if questionnaires.empty?
          erb :questionnaire_not_found, locals: { title: 'Questionnaire Not Found' }
        else
          follow_ups = JSON.parse(RestClient.get("http://#{settings.follow_up_service_host}:#{settings.follow_up_service_port}/FollowUpService/FollowUp/QuestionnaireId=#{questionnaire_id}")).paginate(page: params[:page])
          addresses = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/addresses/#{questionnaires.first['uprn']}"))
          address = addresses.first
          coordinates = "#{address['latitude']},#{address['longitude']}"
          erb :follow_ups, layout: :sidebar_layout,
                           locals: { title: "Questionnaire #{questionnaire_id}",
                                     region_code: address['region11cd'],
                                     local_authority_code: address['lad12cd'],
                                     msoa_code: address['msoa11cd'],
                                     uprn_code: address['uprn'],
                                     questionnaire_id: questionnaire_id,
                                     follow_ups: follow_ups,
                                     questionnaires: questionnaires,
                                     addresses: addresses,
                                     coordinates: coordinates }
        end
      end

      # Present a form for creating a new questionnaire.
      get '/regions/:region_code/las/:local_authority_code/msoas/:msoa_code/addresses/:uprn_code/questionnaires/new' do |region_code, local_authority_code, msoa_code, uprn_code|
        action = "/regions/#{region_code}/las/#{local_authority_code}/msoas/#{msoa_code}/addresses/#{uprn_code}/questionnaires"
        erb :questionnaire, locals: { title: "Create Questionnaire for Address #{uprn_code}",
                                      action: action,
                                      method: :post,
                                      page: params[:page],
                                      region_code: region_code,
                                      local_authority_code: local_authority_code,
                                      msoa_code: msoa_code,
                                      uprn_code: uprn_code,
                                      formtype: '01',
                                      formstatus: 0 }
      end

      # Create a new questionnaire.
      post '/regions/:region_code/las/:local_authority_code/msoas/:msoa_code/addresses/:uprn_code/questionnaires' do |region_code, local_authority_code, msoa_code, uprn_code|
        RestClient.post("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/#{params[:formtype]}/questionnaires",
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
      get '/regions/:region_code/las/:local_authority_code/msoas/:msoa_code/addresses/:uprn_code/questionnaires/:questionnaire_id/edit' do |region_code, local_authority_code, msoa_code, uprn_code, questionnaire_id|
        questionnaires = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/questionnaires/#{questionnaire_id}"))
        questionnaire = questionnaires.first
        action = "/regions/#{region_code}/las/#{local_authority_code}/msoas/#{msoa_code}/addresses/#{uprn_code}/questionnaires/#{questionnaire_id}"

        erb :questionnaire, locals: { title: "Edit Questionnaire #{questionnaire_id} for Address #{uprn_code}",
                                      action: action,
                                      method: :put,
                                      page: params[:page],
                                      region_code: region_code,
                                      local_authority_code: local_authority_code,
                                      msoa_code: msoa_code,
                                      uprn_code: uprn_code,
                                      formtype: questionnaire['formtype'],
                                      formstatus: questionnaire['formstatus'].to_i }
      end

      # Update an existing questionnaire
      put '/regions/:region_code/las/:local_authority_code/msoas/:msoa_code/addresses/:uprn_code/questionnaires/:questionnaire_id' do |region_code, local_authority_code, msoa_code, uprn_code, questionnaire_id|
        RestClient.put("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/questionnaires/#{questionnaire_id}",
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
