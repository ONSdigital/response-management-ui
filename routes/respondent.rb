# Present a form for updating an email address
get '/sampleunitref/:sampleunitref/cases/:case_id/events/:respondent_id/update' do |sampleunitref, case_id, respondent_id|
  authenticate!

  sampleunit = ''
  previous_page_url = request.env['HTTP_REFERER']

  from_respondent = if previous_page_url.end_with? 'events'
                      true
                    else
                      false
                    end

  RestClient::Request.execute(method: :get,
                              url: "#{settings.protocol}://#{settings.party_service_host}:#{settings.party_service_port}/party-api/v1/respondents/id/#{respondent_id}",
                              user: settings.security_user_name,
                              password: settings.security_user_password,
                              realm: settings.security_realm) do |respondent_response, _request, _result, &_block|

    RestClient::Request.execute(method: :get,
                                url: "#{settings.protocol}://#{settings.party_service_host}:#{settings.party_service_port}/party-api/v1/parties/type/B/ref/#{sampleunitref}",
                                user: settings.security_user_name,
                                password: settings.security_user_password,
                                realm: settings.security_realm) do |response, _request, _result, &_block|
      sampleunit = JSON.parse(response) unless response.code == 404
    end

    respondent = JSON.parse(respondent_response) unless respondent_response.code == 404

    erb :respondent, locals: {  title: "Update email for Respondent #{respondent['firstName']} #{respondent['lastName']}",
                                action: "/#{respondent_id}/update",
                                method: :post,
                                page: params[:page],
                                email_address: '',
                                respondent: respondent,
                                sampleunit: sampleunit,
                                previous_page_url: previous_page_url,
                                from_respondent: from_respondent,
                                respondent_id: respondent_id,
                                case_id: case_id,
                                sampleunitref: sampleunitref }

  end
end

post '/:respondent_id/update' do |respondent_id|

  email_address = params[:email_address]
  previous_page_url = params[:previous_page_url]
  old_email = ''

  RestClient::Request.execute(method: :get,
                              url: "#{settings.protocol}://#{settings.party_service_host}:#{settings.party_service_port}/party-api/v1/respondents/id/#{respondent_id}",
                              user: settings.security_user_name,
                              password: settings.security_user_password,
                              realm: settings.security_realm) do |respondent_response, _request, _result, &_block|
    respondent = JSON.parse(respondent_response) unless respondent_response.code == 404
    old_email = respondent['emailAddress']
  end

  RestClient::Request.execute(method: :put,
                              url: "#{settings.protocol}://#{settings.party_service_host}:#{settings.party_service_port}/party-api/v1/respondents/email",
                              user: settings.security_user_name,
                              password: settings.security_user_password,
                              realm: settings.security_realm,
                              payload: {
                                email_address: old_email,
                                new_email_address: email_address
                              }.to_json,
                              headers: { 'Content-Type' => 'application/json' },
                              accept: :json) do |response, _request, _result, &_block|
    if response.code == 200
      flash[:notice] = 'Successfully edited email.'
    else
      logger.error response
      error_flash_text('Unable to edit email', response)
    end

  end

  redirect previous_page_url
end
