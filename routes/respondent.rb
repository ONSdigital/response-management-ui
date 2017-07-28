# Present a form for updating an email address
get '/sampleunitref/:sampleunitref/cases/:case_id/events/:respondent_id/update' do |sampleunitref, case_id, respondent_id|
  authenticate!

  RestClient.get("#{settings.protocol}://#{settings.party_service_host}:#{settings.party_service_port}/party-api/v1/respondents/id/#{respondent_id}") do |respondent_response, _request, _result, &_block|

    respondent = JSON.parse(respondent_response) unless respondent_response.code == 404

    erb :respondent, locals: {  title: "Update email for Respondent #{respondent['firstName']} #{respondent['lastName']}",
                                action: "/sampleunitref/#{sampleunitref}/cases/#{case_id}/events/update",
                                method: :post,
                                page: params[:page],
                                email_address: '',
                                respondent: respondent,
                                respondent_id: respondent_id,
                                case_id: case_id,
                                sampleunitref: sampleunitref }

  end
end

post '/sampleunitref/:sampleunitref/cases/:case_id/events/update' do |sampleunitref, case_id|

  email_address = params[:email_address]

  RestClient.post("#{settings.protocol}://#{settings.notifygateway_host}:#{settings.notifygateway_port}/emails/#{settings.email_template_id}",
                  {
                    emailAddress: email_address,
                    reference: 'Test Email'
                  }.to_json, content_type: :json, accept: :json) do |post_response, _request, _result, &_block|

    if post_response.code == 201
      flash[:notice] = 'Successfully amended email.'
      actions = []

      RestClient.post("#{settings.protocol}://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}/events",
                      {
                        description: 'Placeholder email updated',
                        category: 'MISCELLANEOUS',
                        subCategory: nil,
                        partyId: case_id,
                        createdBy: 'test user Edward'
                      }.to_json, content_type: :json, accept: :json) do |post_response_event, _request, _result, &_block|

        if post_response_event.code == 201
          flash[:notice] = 'Successfully created event.'
          actions = []
        else
          logger.error post_response_event
          error_flash('Unable to create event', post_response_event)
        end
      end

    else
      logger.error post_response
      error_flash('Unable to amend email', post_response)
    end
  end

  event_url = "/sampleunitref/#{sampleunitref}/cases/#{case_id}/events"
  redirect event_url

end
