
# Management home page.
get '/manage' do
  authenticate!
  erb :manage, locals: { title: 'Manage',
                         user: user_role
                        }
end

# Get all escalated cases.
get '/manage/escalated/:escalation_type/:escalation_subtype' do |escalation_type, escalation_subtype|
  authenticate!
  escalations = []
  type = "#{escalation_type.chars.first.upcase}#{escalation_subtype.chars.first.upcase}_ESCALATION"

  RestClient.get("http://#{settings.action_service_host}:#{settings.action_service_port}/actions?actiontype=#{type}&state=PENDING") do |response, _request, _result, &_block|
    escalations = JSON.parse(response).paginate(page: params[:page]) unless response.code == 204
  end

  erb :escalated_cases, locals: { title: "Escalated #{escalation_type.capitalize} #{escalation_subtype.capitalize} Cases", escalations: escalations }
end
