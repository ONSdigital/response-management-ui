# Present a form for updating an email address
get '/sampleunitref/:sampleunitref/cases/:case_id/events/:respondent_id/update' do |sampleunitref, case_id, respondent_id|
  authenticate!

  sampleunit = ''
  previous_page_url = request.env['HTTP_REFERER']

  from_respondent = previous_page_url.end_with? 'events'

  RestClient.get("#{settings.protocol}://#{settings.party_service_host}:#{settings.party_service_port}/party-api/v1/respondents/id/#{respondent_id}") do |respondent_response, _request, _result, &_block|

    RestClient.get("#{settings.protocol}://#{settings.party_service_host}:#{settings.party_service_port}/party-api/v1/parties/type/B/ref/#{sampleunitref}") do |response, _request, _result, &_block|
      sampleunit = JSON.parse(response) unless response.code == 404
    end

    respondent = JSON.parse(respondent_response) unless respondent_response.code == 404

    erb :respondent, locals: {  title: "Update email for Respondent #{respondent['firstName']} #{respondent['lastName']}",
                                action: "/sampleunitref/#{sampleunitref}/cases/#{case_id}/events/update",
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

post '/sampleunitref/:sampleunitref/cases/:case_id/events/update' do

  email_address = params[:email_address]
  previous_page_url = params[:previous_page_url]

  RestClient.post("#{settings.protocol}://#{settings.notifygateway_host}:#{settings.notifygateway_port}/emails/#{settings.email_template_id}",
                  {
                    emailAddress: email_address,
                    reference: 'Test Email'
                  }.to_json, content_type: :json, accept: :json) do |post_response, _request, _result, &_block|

    if post_response.code == 201
      flash[:notice] = 'Successfully amended email.'
      actions = []
    else
      logger.error post_response
      error_flash('Unable to amend email', post_response)
    end
  end

  redirect previous_page_url

end
