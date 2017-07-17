

get '/respondents/:respondentid' do | respondentid |

  respondent = []

  RestClient.get("#{settings.protocol}://#{settings.party_service_host}:#{settings.party_service_port}/party-api/v1/respondents/id/#{respondentid}") do |respondent_response, _request, _result, &_block|
    respondent = JSON.parse(respondent_response) unless respondent_response.code == 404
  end

  erb :respondent, locals: { title: 'Respondents',
                          respondent: respondent }
end
