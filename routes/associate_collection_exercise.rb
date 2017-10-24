class AssocCollex
  attr_accessor :sampleSummaryId, :collectionExerciseId

  def initialize(sampleSummaryId, collectionExerciseId)
      @sampleSummaryId = sampleSummaryId
      @collectionExerciseId = collectionExerciseId
  end
end

get '/associate_collection_exercise' do
  authenticate!

  collectionexercises = []
  samples = []

  #TODO: Add in check to display only Sample Summaries that have not been associated to a collection exercise.
  RestClient::Request.execute(method: :get,
                              url: "#{settings.protocol}://#{settings.sample_service_host}:#{settings.sample_service_port}/samples/samplesummaries",
                              #user: settings.security_user_name,
                              #password: settings.security_user_password,
                              user: 'admin',
                              password: 'secret',
                              realm: settings.security_realm) do |samples_response, _request, _result, &_block|
    samples = JSON.parse(samples_response) unless samples_response.code == 404
  end

  RestClient::Request.execute(method: :get,
                              url: "#{settings.protocol}://#{settings.collection_exercise_service_host}:#{settings.collection_exercise_service_port}/collectionexercises/",
                              #user: settings.security_user_name,
                              #password: settings.security_user_password,
                              user: 'admin',
                              password: 'secret',
                              realm: settings.security_realm) do |collectionexercise_response, _request, _result, &_block|
    collectionexercises = JSON.parse(collectionexercise_response) unless collectionexercise_response.code == 404
  end

  erb :associate_collection_exercise, locals: { title: 'Associate Collection Exercise',
                                                samples: samples,
                                                collectionexercises: collectionexercises }
end

post '/associate_collection_exercise' do

  sampleid = params[:sample]
  collectionexerciseid = params[:collectionexercise]

  samples = Array.new
  samples.push(sampleid)

  puts 'sampleid: ' + sampleid.to_s
  puts 'collectionexerciseid: ' + collectionexerciseid.to_s
  puts 'samples: ' + samples.to_s
  puts 'samplesjson: ' + samples.to_json
  puts "#{settings.protocol}://#{settings.collection_exercise_service_host}:#{settings.collection_exercise_service_port}/collectionexercises/link/#{collectionexerciseid}"

  RestClient::Request.execute(method: :put,
                              url: "#{settings.protocol}://#{settings.collection_exercise_service_host}:#{settings.collection_exercise_service_port}/collectionexercises/link/#{collectionexerciseid}",
                              #user: settings.security_user_name,
                              #password: settings.security_user_password,
                              user: 'admin',
                              password: 'secret',
                              realm: settings.security_realm,
                              payload: {
                                "sampleSummaryIds": samples
                              }.to_json,
                              headers: { 'Content-Type' => 'application/json' }) do |put_response_event, _request, _result, &_block|
                              puts 'request: ' + _request.to_s
                              puts 'put_response_event: ' + put_response_event.to_s

    if put_response_event.code == 200
      flash[:notice] = 'Collection Exercise successfully associated.'
    else
      logger.error put_response_event
      error_flash('Error associating sample to Collection Exercise', put_response_event)
    end

    event_url = '/associate_collection_exercise'
    redirect event_url

  end

end
