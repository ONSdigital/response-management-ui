get '/associate_collection_exercise' do
  authenticate!

  collectionexercises = []

  RestClient::Request.execute(method: :get,
                              url: "#{settings.protocol}://#{settings.collection_exercise_service_host}:#{settings.collection_exercise_service_port}/collectionexercises/",
                              user: settings.security_user_name,
                              password: settings.security_user_password,
                              realm: settings.security_realm) do |collectionexercise_response, _request, _result, &_block|
    collectionexercises = JSON.parse(collectionexercise_response) unless collectionexercise_response.code == 404
  end

  erb :associate_collection_exercise, locals: { title: 'Associate Collection Exercise',
                                                collectionexercises: collectionexercises }
end

post '/associate_collection_exercise' do

  collectionexercise = params[:collectionexercise]

  RestClient::Request.execute(method: :put,
                              url: "#{settings.protocol}://#{settings.collection_exercise_service_host}:#{settings.collection_exercise_service_port}/collectionexercises/#{collectionexercise}",
                              user: settings.security_user_name,
                              password: settings.security_user_password,
                              realm: settings.security_realm,
                              payload: {},
                              headers: { 'Content-Type' => 'application/json' },
                              accept: :json) do |put_response_event, _request, _result, &_block|

    if put_response_event.code == 200
      flash[:notice] = 'Collection Exercise successfully associated.'
    else
      puts put_response_event.to_s
      logger.error put_response_event
      error_flash('Error associating sample to Collection Exercise', put_response_event)
    end

    event_url = '/associate_collection_exercise'
    redirect event_url

  end

end
