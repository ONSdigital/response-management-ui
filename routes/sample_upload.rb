get '/sample_upload' do
  authenticate!

  surveys = []

  RestClient::Request.execute(method: :get,
                              url: "#{settings.protocol}://#{settings.survey_service_host}:#{settings.survey_service_port}/surveys",
                              #user: settings.security_user_name,
                              #password: settings.security_user_password,
                              user: 'admin',
                              password: 'secret',
                              realm: settings.security_realm) do |surveys_response, _request, _result, &_block|
    surveys = JSON.parse(surveys_response) unless surveys_response.code == 404
  end

  erb :sample_upload, locals: { title: 'Sample Upload',
                                surveys: surveys }
end

post '/sample_upload' do

  sample_file_path = params[:sample_file][:tempfile].path
  survey_type = params[:survey_type]
  event_url = ''

  RestClient::Request.execute(method: :post,
                              url: "#{settings.protocol}://#{settings.sample_service_host}:#{settings.sample_service_port}/samples/#{survey_type}/fileupload",
                              #user: settings.security_user_name,
                              #password: settings.security_user_password,
                              user: 'admin',
                              password: 'secret',
                              realm: settings.security_realm,
                              payload: {
                                multipart: true,
                                file: File.new(sample_file_path, 'r')
                              }) do |post_response_event, _request, _result, &_block|

    if post_response_event.code == 201
      flash[:notice] = 'Sample successfully uploaded.'
      event_url = '/associate_collection_exercise'
    else
      puts post_response_event.to_s
      logger.error post_response_event
      error_flash('Error uploading sample', post_response_event)
      event_url = '/sample_upload'
    end

  end

  redirect event_url

end
