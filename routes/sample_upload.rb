get '/sample_upload' do
  authenticate!

  surveys = []

  RestClient::Request.execute(method: :get,
                              url: "#{settings.protocol}://#{settings.survey_service_host}:#{settings.survey_service_port}/surveys",
                              user: settings.security_user_name,
                              password: settings.security_user_password,
                              realm: settings.security_realm) do |surveys_response, _request, _result, &_block|
    surveys = JSON.parse(surveys_response) unless surveys_response.code == 404
  end

  erb :sample_upload, locals: { title: 'Sample Upload',
  surveys: surveys }
end


post '/sample_upload' do

  sample_file_path = params[:sample_file][:tempfile].path
  survey_type = params[:survey_type]

  RestClient::Request.execute(method: :post,
    url: "#{settings.protocol}://#{settings.sample_service_host}:#{settings.sample_service_port}/samples/#{survey_type}/fileupload",
    user: settings.security_user_name,
    password: settings.security_user_password,
    realm: settings.security_realm,
    payload: {
      :multipart => true,
      :file => File.new(sample_file_path, 'r')
    }) do |post_response_event, _request, _result, &_block|

    parsed_response = JSON.parse(post_response_event) unless post_response_event.code == 404

  end

end
