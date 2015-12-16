module Beyond
  module Routes
    class FollowUpService < Base

      # Get all follow-ups for the selected questionnaire.
      get '/regions/:region_code/las/:local_authority_code/msoas/:msoa_code/addresses/:uprn_code/questionnaires/:questionnaire_id' do |region_code, local_authority_code, msoa_code, uprn_code, questionnaire_id|
        follow_ups = JSON.parse(RestClient.get("http://#{settings.follow_up_service_host}:#{settings.follow_up_service_port}/FollowUpService/FollowUp/QuestionnaireId=#{questionnaire_id}")).paginate(page: params[:page])

        # Get the selected address and quesionnaire details so they can be redisplayed for reference.
        addresses = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/addresses/#{uprn_code}"))
        coordinates = "#{addresses.first['latitude']},#{addresses.first['longitude']}"
        questionnaires = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/questionnaires/#{questionnaire_id}"))
        erb :follow_ups, layout: :sidebar_layout,
                         locals: { title: "Follow-Ups for Questionnaire #{questionnaire_id}",
                                   region_code: region_code,
                                   local_authority_code: local_authority_code,
                                   msoa_code: msoa_code,
                                   uprn_code: uprn_code,
                                   questionnaire_id: questionnaire_id,
                                   follow_ups: follow_ups,
                                   questionnaires: questionnaires,
                                   addresses: addresses,
                                   coordinates: coordinates }
      end

      # Present a form for creating a new follow-up.
      get '/regions/:region_code/las/:local_authority_code/msoas/:msoa_code/addresses/:uprn_code/questionnaires/:questionnaire_id/followups/new' do |region_code, local_authority_code, msoa_code, uprn_code, questionnaire_id|
        action = "/regions/#{region_code}/las/#{local_authority_code}/msoas/#{msoa_code}/addresses/#{uprn_code}/questionnaires/#{questionnaire_id}/followups"
        erb :follow_up, locals: { title: "Create Follow-Up for Questionnaire #{questionnaire_id}",
                                  action: action,
                                  method: :post,
                                  page: params[:page],
                                  region_code: region_code,
                                  local_authority_code: local_authority_code,
                                  msoa_code: msoa_code,
                                  uprn_code: uprn_code,
                                  questionnaire_id: questionnaire_id,
                                  contactname: '',
                                  type: 'Visit',
                                  priority: 'Medium',
                                  casenotes: '',
                                  language: '',
                                  visit_date: '',
                                  visit_hours: '9',
                                  visit_minutes: '30' }
      end

      # Create a new follow-up.
      post '/regions/:region_code/las/:local_authority_code/msoas/:msoa_code/addresses/:uprn_code/questionnaires/:questionnaire_id/followups' do |region_code, local_authority_code, msoa_code, uprn_code, questionnaire_id|
        form do
          field :contactname, present: true
        end

        if form.failed?
          action = "/regions/#{region_code}/las/#{local_authority_code}/msoas/#{msoa_code}/addresses/#{uprn_code}/questionnaires/#{questionnaire_id}/followups"
          output = erb :follow_up, locals: { title: "Create Follow-Up for Questionnaire #{questionnaire_id}",
                                             action: action,
                                             method: :post,
                                             page: params[:page],
                                             region_code: region_code,
                                             local_authority_code: local_authority_code,
                                             msoa_code: msoa_code,
                                             uprn_code: uprn_code,
                                             questionnaire_id: questionnaire_id,
                                             contactname: params[:contactname],
                                             type: params[:type],
                                             priority: params[:priority],
                                             casenotes: params[:casenotes],
                                             language: params[:language],
                                             visit_date: params[:visitdate],
                                             visit_hours: params[:visithours],
                                             visit_minutes: params[:visitmins] }
          fill_in_form(output)
        else
          visit_time = nil
          if params[:visitdate].present?
            visit_time = Date.string_to_epoch_time("#{params[:visitdate]} #{params[:visithours]}:#{params[:visitmins]}")
          end

          RestClient.post("http://#{settings.follow_up_service_host}:#{settings.follow_up_service_port}/FollowUpService/FollowUp",
                          { questionnaireid: questionnaire_id,
                            contactname: params[:contactname],
                            type: params[:type].upcase,
                            casenotes: params[:casenotes],
                            priority: params[:priority],
                            language: params[:language],
                            visittime: visit_time
                          }.to_json, content_type: :json, accept: :json
                         ) do |response, _request, _result, &_block|
            if response.code == 200
              flash[:notice] = 'Successfully created follow-up.'
            else
              flash[:error] = "Unable to create follow-up (HTTP #{response.code} received)."
            end
          end

          follow_ups_url = "/regions/#{region_code}/las/#{local_authority_code}/msoas/#{msoa_code}/addresses/#{uprn_code}/questionnaires/#{questionnaire_id}"
          follow_ups_url += "?page=#{params[:page]}" if params[:page].present?
          redirect follow_ups_url
        end
      end

      # Present a form for editing an existing follow-up.
      get '/regions/:region_code/las/:local_authority_code/msoas/:msoa_code/addresses/:uprn_code/questionnaires/:questionnaire_id/followups/:follow_up_id/edit' do |region_code, local_authority_code, msoa_code, uprn_code, questionnaire_id, follow_up_id|
        follow_ups = JSON.parse(RestClient.get("http://#{settings.follow_up_service_host}:#{settings.follow_up_service_port}/FollowUpService/FollowUp/CorrelationId=#{follow_up_id}"))
        follow_up = follow_ups.first
        action = "/regions/#{region_code}/las/#{local_authority_code}/msoas/#{msoa_code}/addresses/#{uprn_code}/questionnaires/#{questionnaire_id}/followups/#{follow_up_id}"

        visit_date = ''
        visit_hours = '9'
        visit_minutes = '30'

        if follow_up['visittime'].present?
          visit_date = follow_up['visittime'].to_date(time: false)
          visit_hours = follow_up['visittime'].to_hours
          visit_minutes = follow_up['visittime'].to_minutes
        end

        erb :follow_up, locals: { title: "Edit Follow-Up for Questionnaire #{questionnaire_id}",
                                  action: action,
                                  method: :put,
                                  page: params[:page],
                                  region_code: region_code,
                                  local_authority_code: local_authority_code,
                                  msoa_code: msoa_code,
                                  uprn_code: uprn_code,
                                  questionnaire_id: questionnaire_id,
                                  contactname: follow_up['contactname'],
                                  type: follow_up['type'],
                                  priority: follow_up['priority'],
                                  casenotes: follow_up['casenotes'],
                                  language: follow_up['language'],
                                  visit_date: visit_date,
                                  visit_hours: visit_hours,
                                  visit_minutes: visit_minutes }
      end

      # Update an existing follow-up.
      put '/regions/:region_code/las/:local_authority_code/msoas/:msoa_code/addresses/:uprn_code/questionnaires/:questionnaire_id/followups/:follow_up_id' do |region_code, local_authority_code, msoa_code, uprn_code, questionnaire_id, follow_up_id|
        form do
          field :contactname, present: true
        end

        if form.failed?
          action = "/regions/#{region_code}/las/#{local_authority_code}/msoas/#{msoa_code}/addresses/#{uprn_code}/questionnaires/#{questionnaire_id}/followups/#{follow_up_id}"
          output = erb :follow_up, locals: { title: "Edit Follow-Up for Questionnaire #{questionnaire_id}",
                                             action: action,
                                             method: :put,
                                             page: params[:page],
                                             region_code: region_code,
                                             local_authority_code: local_authority_code,
                                             msoa_code: msoa_code,
                                             uprn_code: uprn_code,
                                             questionnaire_id: questionnaire_id,
                                             contactname: params[:contactname],
                                             type: params[:type],
                                             priority: params[:priority],
                                             casenotes: params[:casenotes],
                                             language: params[:language],
                                             visit_date: params[:visitdate],
                                             visit_hours: params[:visithours],
                                             visit_minutes: params[:visitmins] }
          fill_in_form(output)
        else
          visit_time = nil
          if params[:visitdate].present?
            visit_time = Date.string_to_epoch_time("#{params[:visitdate]} #{params[:visithours]}:#{params[:visitmins]}")
          end

          RestClient.put("http://#{settings.follow_up_service_host}:#{settings.follow_up_service_port}/FollowUpService/FollowUp/#{follow_up_id}",
                         { questionnaireid: questionnaire_id,
                           contactname: params[:contactname],
                           type: params[:type].upcase,
                           casenotes: params[:casenotes],
                           priority: params[:priority],
                           language: params[:language],
                           visittime: visit_time
                         }.to_json, content_type: :json, accept: :json
                        ) do |response, _request, _result, &_block|
            if response.code == 200
              flash[:notice] = 'Successfully updated follow-up.'
            else
              flash[:error] = "Unable to update follow-up (HTTP #{response.code} received)."
            end
          end

          follow_ups_url = "/regions/#{region_code}/las/#{local_authority_code}/msoas/#{msoa_code}/addresses/#{uprn_code}/questionnaires/#{questionnaire_id}"
          follow_ups_url += "?page=#{params[:page]}" if params[:page].present?
          redirect follow_ups_url
        end
      end

      # Delete (i.e. cancel) the selected follow-up.
      delete '/regions/:region_code/las/:local_authority_code/msoas/:msoa_code/addresses/:uprn_code/questionnaires/:questionnaire_id/followups/:follow_up_id' do |region_code, local_authority_code, msoa_code, uprn_code, questionnaire_id, follow_up_id|
        RestClient.put("http://#{settings.follow_up_service_host}:#{settings.follow_up_service_port}/FollowUpService/FollowUp/#{follow_up_id}",
                       { updateAction: 'CANCEL' }.to_json, content_type: :json, accept: :json
                      ) do |response, _request, _result, &_block|
          if response.code == 200
            flash[:notice] = 'Cancelling follow-up.'
          else
            flash[:error] = "Unable to cancel follow-up (HTTP #{response.code} received)."
          end
        end

        follow_ups_url = "/regions/#{region_code}/las/#{local_authority_code}/msoas/#{msoa_code}/addresses/#{uprn_code}/questionnaires/#{questionnaire_id}"
        follow_ups_url += "?page=#{params[:page]}" if params[:page].present?
        redirect follow_ups_url
      end

      # Delete (i.e. mark as reviewed) the selected follow-up review.
      delete '/regions/:region_code/las/:local_authority_code/msoas/:msoa_code/addresses/:uprn_code/followups/:follow_up_id/review' do |region_code, local_authority_code, msoa_code, uprn_code, follow_up_id|
        RestClient.put("http://#{settings.follow_up_service_host}:#{settings.follow_up_service_port}/FollowUpService/FollowUp/#{follow_up_id}",
                       { updateAction: 'REVIEWED_ALL_ADDRESSNOTES' }.to_json, content_type: :json, accept: :json
                      ) do |response, _request, _result, &_block|
          if response.code == 200
            flash[:notice] = 'Marking follow-up as reviewed.'
          else
            flash[:error] = "Unable to mark follow-up as reviewed (HTTP #{response.code} received)."
          end
        end

        addresses_url = "/regions/#{region_code}/las/#{local_authority_code}/msoas/#{msoa_code}/addresses/review"
        addresses_url += "?page=#{params[:page]}" if params[:page].present?
        redirect addresses_url
      end
    end
  end
end
