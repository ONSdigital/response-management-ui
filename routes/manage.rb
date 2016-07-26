
# Management home page.
get '/manage' do
  authenticate!
  erb :manage, locals: { title: 'Manage' }
end

# Get all escalated cases.
get '/manage/escalated/:escalation_type' do |escalation_type|  
  authenticate!
  escalations = []
  type = "#{escalation_type.capitalize}Escalation"

  RestClient.get("http://#{settings.action_service_host}:#{settings.action_service_port}/actions?actiontype=#{type}&state=PENDING") do |response, _request, _result, &_block|
    escalations = JSON.parse(response).paginate(page: params[:page]) unless response.code == 204
  end

  erb :escalated_cases, locals: { title: "Escalated #{escalation_type.capitalize} Cases", escalations: escalations }
end
