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

      # Get all caseloads for the selected LA.
      get '/regions/:region_code/las/:local_authority_code/caseloads' do |region_code, local_authority_code|
        caseloads = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/caseloads?ladid=#{local_authority_code}")).paginate(page: params[:page])
        erb :caseloads, locals: { title: "Caseloads for LA #{local_authority_code}",
                                  region_code: region_code,
                                  local_authority_code: local_authority_code,
                                  caseloads: caseloads }
      end

      # Get all addresses for the selected caseload.
      get '/regions/:region_code/las/:local_authority_code/caseloads/:caseload_code/addresses' do |region_code, local_authority_code, caseload_code|
        addresses = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/addresses?caseloadid=#{caseload_code}")).paginate(page: params[:page])
        erb :addresses, locals: { title: "Addresses for Caseload #{caseload_code}",
                                  region_code: region_code,
                                  local_authority_code: local_authority_code,
                                  caseload_code: caseload_code,
                                  addresses: addresses }
      end

      # Get all the addresses to review for the selected caseload.
      get '/regions/:region_code/las/:local_authority_code/caseloads/:caseload_code/addresses/review' do |region_code, local_authority_code, caseload_code|
        addresses = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/addresses?caseloadid=#{caseload_code}&notestoreview=true")).paginate(page: params[:page])
        erb :review_addresses, locals: { title: "Review Addresses Notes for Caseload #{caseload_code}",
                                         region_code: region_code,
                                         local_authority_code: local_authority_code,
                                         caseload_code: caseload_code,
                                         addresses: addresses }
      end

      # Present a form for reviewing the address notes for an existing address.
      get '/regions/:region_code/las/:local_authority_code/caseloads/:caseload_code/addresses/:address_id/review' do |region_code, local_authority_code, caseload_code, address_id|
        addresses = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/addresses/#{address_id}"))
        address = addresses.first
        coordinates = "#{address['latitude']},#{address['longitude']}"
        follow_ups = JSON.parse(RestClient.get("http://#{settings.follow_up_service_host}:#{settings.follow_up_service_port}/FollowUpService/FollowUp/AddressId=#{address_id}")).paginate(page: params[:page])
        action = "/regions/#{region_code}/las/#{local_authority_code}/caseloads/#{caseload_code}/addresses/#{address_id}/review"

        erb :review_address, layout: :sidebar_layout,
                             locals: { title: "Review Address #{address_id} for Caseload #{caseload_code}",
                                       action: action,
                                       method: :put,
                                       page: params[:page],
                                       region_code: region_code,
                                       local_authority_code: local_authority_code,
                                       caseload_code: caseload_code,
                                       addresstype: address['addresstype'],
                                       addgridref: address['addgridref'],
                                       enumerationtype: address['enumerationtype'],
                                       estabtype: address['estabtype'],
                                       hardtocount: address['hardtocount'],
                                       estabname: address['estabname'].to_title_case,
                                       namemanager: address['namemanager'].to_title_case,
                                       buildingname: address['buildingname'].to_title_case,
                                       subbuildingname: address['subbuildingname'].to_title_case,
                                       buildingnumber: address['buildingnumber'],
                                       thoroughfarename: address['thoroughfarename'].to_title_case,
                                       posttown: address['posttown'].to_title_case,
                                       postcode: address['postcode'],
                                       telnumber: address['telnumber'].to_phone_number,
                                       coordinates: coordinates,
                                       follow_ups: follow_ups,
                                       address_id: address['addressid'] }
      end

      # Present a form for creating a new address.
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

      # Create a new address.
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

      # Present a form for editing an existing address.
      get '/regions/:region_code/las/:local_authority_code/caseloads/:caseload_code/addresses/:address_id/edit' do |region_code, local_authority_code, caseload_code, address_id|
        addresses = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/addresses/#{address_id}"))
        address = addresses.first
        coordinates = "#{address['latitude']},#{address['longitude']}"
        action = "/regions/#{region_code}/las/#{local_authority_code}/caseloads/#{caseload_code}/addresses/#{address_id}"

        erb :address, layout: :sidebar_layout,
                      locals: { title: "Edit Address #{address_id} for Caseload #{caseload_code}",
                                action: action,
                                method: :put,
                                page: params[:page],
                                region_code: region_code,
                                local_authority_code: local_authority_code,
                                caseload_code: caseload_code,
                                addresstype: address['addresstype'],
                                addgridref: address['addgridref'],
                                enumerationtype: address['enumerationtype'],
                                estabtype: address['estabtype'],
                                hardtocount: address['hardtocount'],
                                estabname: address['estabname'].to_title_case,
                                namemanager: address['namemanager'].to_title_case,
                                buildingname: address['buildingname'].to_title_case,
                                subbuildingname: address['subbuildingname'].to_title_case,
                                buildingnumber: address['buildingnumber'],
                                thoroughfarename: address['thoroughfarename'].to_title_case,
                                posttown: address['posttown'].to_title_case,
                                postcode: address['postcode'],
                                telnumber: address['telnumber'].to_phone_number,
                                coordinates: coordinates }
      end

      # Update an existing address (either directly or by reviewing its address notes).
      ['/regions/:region_code/las/:local_authority_code/caseloads/:caseload_code/addresses/:address_id',
       '/regions/:region_code/las/:local_authority_code/caseloads/:caseload_code/addresses/:address_id/review'].each do |path|
        put path do
          reviewing = path.end_with? 'review'

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
            action = "/regions/#{params[:region_code]}/las/#{params[:local_authority_code]}/caseloads/#{params[:caseload_code]}/addresses/#{params[:address_id]}"
            locals = { method: :put,
                       page: params[:page],
                       region_code: params[:region_code],
                       local_authority_code: params[:local_authority_code],
                       caseload_code: params[:caseload_code],
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

            if reviewing
              action += '/review'
              addresses = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/addresses/#{params[:address_id]}"))
              address = addresses.first
              coordinates = "#{address['latitude']},#{address['longitude']}"
              follow_ups = JSON.parse(RestClient.get("http://#{settings.follow_up_service_host}:#{settings.follow_up_service_port}/FollowUpService/FollowUp/AddressId=#{params[:address_id]}")).paginate(page: params[:page])
              output = erb :review_address, layout: :sidebar_layout,
                                            locals: { title: "Review Address #{params[:address_id]} for Caseload #{params[:caseload_code]}",
                                                      action: action,
                                                      coordinates: coordinates,
                                                      follow_ups: follow_ups,
                                                      address_id: address['addressid'] }.merge(locals)
            else
              output = erb :address, locals: { title: "Edit Address for Caseload #{params[:caseload_code]}",
                                               action: action }.merge(locals)
            end

            fill_in_form(output)
          else
            RestClient.put("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/addresses/#{params[:address_id]}",
                           { addgridref: params[:addgridref],
                             addresstype: params[:addresstype],
                             buildingname: params[:buildingname],
                             buildingnumber: params[:buildingnumber],
                             caseload: params[:caseload_code],
                             enumerationtype: params[:enumerationtype],
                             estabname: params[:estabname],
                             estabtype: params[:estabtype],
                             hardtocount: params[:hardtocount].to_i,
                             lad12cd: params[:local_authority_code],
                             namemanager: params[:namemanager],
                             postcode: params[:postcode],
                             posttown: params[:posttown],
                             rgn11cd: params[:region_code],
                             subbuildingname: params[:subbuildingname],
                             telnumber: params[:telnumber],
                             thoroughfarename: params[:thoroughfarename]
                           }.to_json, content_type: :json, accept: :json
                          ) do |response, _request, _result, &_block|
              if response.code == 200
                flash[:notice] = 'Successfully updated address.'
              else
                flash[:error] = "Unable to update address (HTTP #{response.code} received)."
              end
            end

            addresses_url = "/regions/#{params[:region_code]}/las/#{params[:local_authority_code]}/caseloads/#{params[:caseload_code]}/addresses"
            addresses_url += '/review' if reviewing
            addresses_url += "?page=#{params[:page]}" if params[:page].present?
            redirect addresses_url
          end
        end
      end

      # Get all questionnaires for the selected address.
      get '/regions/:region_code/las/:local_authority_code/caseloads/:caseload_code/addresses/:address_id/questionnaires' do |region_code, local_authority_code, caseload_code, address_id|
        questionnaires = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/questionnaires?addressid=#{address_id}")).paginate(page: params[:page])

        # Get the selected address details so they can be redisplayed for reference.
        addresses = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/addresses/#{address_id}"))
        coordinates = "#{addresses.first['latitude']},#{addresses.first['longitude']}"
        erb :questionnaires, layout: :sidebar_layout,
                             locals: { title: "Questionnaires for Address #{address_id}",
                                       region_code: region_code,
                                       local_authority_code: local_authority_code,
                                       caseload_code: caseload_code,
                                       address_id: address_id,
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
          addresses = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/addresses/#{questionnaires.first['addressid']}"))
          address = addresses.first
          coordinates = "#{address['latitude']},#{address['longitude']}"
          erb :follow_ups, layout: :sidebar_layout,
                           locals: { title: "Questionnaire #{questionnaire_id}",
                                     region_code: address['rgn11cd'],
                                     local_authority_code: address['lad12cd'],
                                     caseload_code: address['caseload'],
                                     address_id: address['addressid'],
                                     questionnaire_id: questionnaire_id,
                                     follow_ups: follow_ups,
                                     questionnaires: questionnaires,
                                     addresses: addresses,
                                     coordinates: coordinates }
        end
      end

      # Present a form for creating a new questionnaire.
      get '/regions/:region_code/las/:local_authority_code/caseloads/:caseload_code/addresses/:address_id/questionnaires/new' do |region_code, local_authority_code, caseload_code, address_id|
        action = "/regions/#{region_code}/las/#{local_authority_code}/caseloads/#{caseload_code}/addresses/#{address_id}/questionnaires"
        erb :questionnaire, locals: { title: "Create Questionnaire for Address #{address_id}",
                                      action: action,
                                      method: :post,
                                      page: params[:page],
                                      region_code: region_code,
                                      local_authority_code: local_authority_code,
                                      caseload_code: caseload_code,
                                      address_id: address_id,
                                      formtype: '01',
                                      formstatus: 0 }
      end

      # Create a new questionnaire.
      post '/regions/:region_code/las/:local_authority_code/caseloads/:caseload_code/addresses/:address_id/questionnaires' do |region_code, local_authority_code, caseload_code, address_id|
        RestClient.post("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/#{params[:formtype]}/questionnaires",
                        { addressid: address_id,
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

        questionnaires_url = "/regions/#{region_code}/las/#{local_authority_code}/caseloads/#{caseload_code}/addresses/#{address_id}/questionnaires"
        questionnaires_url += "?page=#{params[:page]}" if params[:page].present?
        redirect questionnaires_url
      end

      # Present a form for editing an existing questionnaire.
      get '/regions/:region_code/las/:local_authority_code/caseloads/:caseload_code/addresses/:address_id/questionnaires/:questionnaire_id/edit' do |region_code, local_authority_code, caseload_code, address_id, questionnaire_id|
        questionnaires = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/questionnaires/#{questionnaire_id}"))
        questionnaire = questionnaires.first
        action = "/regions/#{region_code}/las/#{local_authority_code}/caseloads/#{caseload_code}/addresses/#{address_id}/questionnaires/#{questionnaire_id}"

        erb :questionnaire, locals: { title: "Edit Questionnaire #{questionnaire_id} for Address #{address_id}",
                                      action: action,
                                      method: :put,
                                      page: params[:page],
                                      region_code: region_code,
                                      local_authority_code: local_authority_code,
                                      caseload_code: caseload_code,
                                      address_id: address_id,
                                      formtype: questionnaire['formtype'],
                                      formstatus: questionnaire['formstatus'].to_i }
      end

      # Update an existing questionnaire.
      put '/regions/:region_code/las/:local_authority_code/caseloads/:caseload_code/addresses/:address_id/questionnaires/:questionnaire_id' do |region_code, local_authority_code, caseload_code, address_id, questionnaire_id|
        RestClient.put("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/questionnaires/#{questionnaire_id}",
                       { addressid: address_id,
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

        questionnaires_url = "/regions/#{region_code}/las/#{local_authority_code}/caseloads/#{caseload_code}/addresses/#{address_id}/questionnaires"
        questionnaires_url += "?page=#{params[:page]}" if params[:page].present?
        redirect questionnaires_url
      end
    end
  end
end
