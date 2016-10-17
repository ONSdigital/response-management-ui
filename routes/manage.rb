
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
  casegroup = []
  type = "#{escalation_type.chars.first.upcase}#{escalation_subtype.chars.first.upcase}_ESCALATION"

  RestClient.get("http://#{settings.action_service_host}:#{settings.action_service_port}/actions?actiontype=#{type}&state=PENDING") do |response, _request, _result, &_block|
    escalations = JSON.parse(response).paginate(page: params[:page]) unless response.code == 204
  end

  escalations.each do |escalation|
    case_id = escalation['caseId']
    kase = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/cases/#{case_id}"))
    casegroup_id = kase['caseGroupId']
    casegroup = JSON.parse(RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/casegroups/#{casegroup_id}"))
    logger.info casegroup['sampleId']

    logger.info casegroup['uprn']

    escalation['uprn'] = casegroup['uprn']
    escalation['sampleId'] = casegroup['sampleId']
  end

  erb :escalated_cases, locals: { title: "Escalated #{escalation_type.capitalize} #{escalation_subtype.capitalize} Cases",
                                  escalations: escalations
                                }
end
