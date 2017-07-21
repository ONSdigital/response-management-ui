# Present a form for updating an email address
get '/sampleunitref/:sampleunitref/cases/:case_id/events/:respondent_id/update' do |sampleunitref, case_id, respondent_id|
  authenticate!

  RestClient.get("#{settings.protocol}://#{settings.party_service_host}:#{settings.party_service_port}/party-api/v1/respondents/id/#{respondent_id}") do |respondent_response, _request, _result, &_block|

    respondent = JSON.parse(respondent_response) unless respondent_response.code == 404

    puts respondent
    puts respondent['firstName']
    puts respondent['lastName']

    erb :respondent, locals: { title: "Update email for Respondent " + respondent['firstName'] + " " + respondent['lastName'],
                          action: "/sampleunitref/#{sampleunitref}/cases/#{case_id}/events/#{respondent_id}",
                          method: :post,
                          page: params[:page],
                          emailaddress: '',
                          respondent: respondent,
                          respondent_id: respondent_id,
                          case_id: case_id,
                          sampleunitref: sampleunitref }

  end
end

post '/sampleunitref/:sampleunitref/cases/:case_id/events' do |sampleunitref, case_id|

  emailaddress = params[:emailaddress]

  RestClient.post("#{settings.protocol}://#{settings.notifygateway_host}:#{settings.notifygateway_port}/notify/emails/#{settings.email_template_id}",
                  {
                    emailaddress: emailaddress
                  }.to_json, content_type: :json, accept: :json) do |post_response, _request, _result, &_block|

    puts 'post response ' + post_response
    puts 'post response code ' + post_response.code.to_s

    #Change back to 201
    if post_response.code == 200
      flash[:notice] = 'Successfully amended email.'
      actions = []
    else
      logger.error post_response
      error_flash('Unable to amend email', post_response)
    end
  end

  event_url = "/sampleunitref/#{sampleunitref}/cases/#{case_id}/events"
  redirect event_url

end
