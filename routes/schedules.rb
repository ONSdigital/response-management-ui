get '/surveys' do

  surveys = []

  RestClient::Request.execute(method: :get,
                              url: "#{settings.protocol}://#{settings.survey_service_host}:#{settings.survey_service_port}/surveys",
                              user: settings.security_user_name,
                              password: settings.security_user_password,
                              realm: settings.security_realm) do |response, _request, _result, &_block|
    surveys = JSON.parse(response) unless response.code == 404
  end

  surveys.each do |survey|
    surveyid      = survey['id']

    RestClient::Request.execute(method: :get,
                                url: "#{settings.protocol}://#{settings.survey_service_host}:#{settings.survey_service_port}/surveys/#{surveyid}",
                                user: settings.security_user_name,
                                password: settings.security_user_password,
                                realm: settings.security_realm) do |response, _request, _result, &_block|
      surveydetails = JSON.parse(response) unless response.code == 404
      survey['longName'] = surveydetails['longName']
    end
  end

  erb :surveys, locals: { title: "List of Surveys",
                                   surveys: surveys
                                  }
end

get '/collectionexercises/:surveyid' do |surveyid|

  collectionexercises = []
  survey              = []
  surveyname          = ""


  RestClient::Request.execute(method: :get,
                              url: "#{settings.protocol}://#{settings.collection_exercise_service_host}:#{settings.collection_exercise_service_port}/collectionexercises/survey/#{surveyid}",
                              user: settings.security_user_name,
                              password: settings.security_user_password,
                              realm: settings.security_realm) do |response, _request, _result, &_block|
    collectionexercises = JSON.parse(response) unless response.code == 404
  end

  RestClient::Request.execute(method: :get,
                              url: "#{settings.protocol}://#{settings.survey_service_host}:#{settings.survey_service_port}/surveys/#{surveyid}",
                              user: settings.security_user_name,
                              password: settings.security_user_password,
                              realm: settings.security_realm) do |response, _request, _result, &_block|
    survey = JSON.parse(response) unless response.code == 404
    surveyname = survey['longName']
  end


  erb :collectionexercises, locals: { title: "List of Collection Exercises for #{surveyname}",
                                   collectionexercises: collectionexercises
                                  }
end

get '/schedule/collectionexercise/:collectionexercise' do |collectionexerciseid|
  authenticate!
  collectionexercise = []
  actionplans = []

  RestClient::Request.execute(method: :get,
                            url: "#{settings.protocol}://#{settings.collection_exercise_service_host}:#{settings.collection_exercise_service_port}/collectionexercises/#{collectionexerciseid}",
                            user: settings.security_user_name,
                            password: settings.security_user_password,
                            realm: settings.security_realm) do |response, _request, _result, &_block|
    collectionexercise = JSON.parse(response) unless response.code == 404
    actionplans = collectionexercise['caseTypes']
  end

  actionplans.each do |actionplan|
    actionplanid      = actionplan['actionPlanId']

    actionplandetails = JSON.parse(RestClient::Request.execute(method: :get,
                                                               url: "#{settings.protocol}://#{settings.action_service_host}:#{settings.action_service_port}/actionplans/#{actionplanid}",
                                                               user: settings.security_user_name,
                                                               password: settings.security_user_password,
                                                               realm: settings.security_realm))
    actionplan['name']        = actionplandetails['name']
    actionplan['description'] = actionplandetails['description']
  end

  erb :collectionexercise, locals: { title: "Schedule for Collection Exercise #{collectionexerciseid}",
                                     collectionexercise: collectionexercise,
                                     collectionexerciseid: collectionexerciseid,
                                     actionplans: actionplans
                                    }
end
