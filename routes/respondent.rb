get '/respondents/:respondentid' do |respondentid|

  respondent = []

  RestClient.get("#{settings.protocol}://#{settings.party_service_host}:#{settings.party_service_port}/party-api/v1/respondents/id/#{respondentid}") do |respondent_response, _request, _result, &_block|
    respondent = JSON.parse(respondent_response) unless respondent_response.code == 404
  end

  puts respondent

  erb :respondent, locals: {  title: 'Respondents',
                              respondent: respondent }
end

post '/respondents/amendemail' do

  email_template_id = '290b93f2-04c2-413d-8f9b-93841e684e90'

  # Pass through emailaddress as param when endpoint updated
  # emailaddress = params[:emailaddresstext]
  # puts emailaddress

  RestClient.post("#{settings.protocol}://#{settings.notifygateway_host}:#{settings.notifygateway_port}/notify/emails/#{email_template_id}",
                  {}.to_json, content_type: :json, accept: :json) do |post_response, _request, _result, &_block|

    if post_response.code == 201
      flash[:notice] = 'Successfully amended email.'
      actions = []
    else
      logger.error post_response
      error_flash('Unable to amend email', post_response)
    end
  end

  erb :emailamended, locals: { title: 'Email Amended' }
end
