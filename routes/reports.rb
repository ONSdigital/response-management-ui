def type_format(report_type)
  formatted_type = report_type.tr('_', ' ').split.map(&:capitalize).join(' ')
  formatted_type[1] = formatted_type[1].upcase if formatted_type[2] == ' '
  formatted_type
end

helpers do
 def host_and_port_for_report_class(report_class)
   case report_class
     when 'action-exporter'
       return settings.action_exporter_host, settings.action_exporter_port
     when 'actionsvc'
       return settings.action_service_host, settings.action_service_port
     when 'case'
       return settings.case_service_host, settings.case_service_port
     when 'collection-exercise'
       return settings.collection_exercise_service_host, settings.collection_exercise_service_port
     when 'sample'
       return settings.sample_service_host, settings.sample_service_port
   end
 end
end

get '/reports' do
  authenticate!
  case_report_types = []
  action_report_types = []
  RestClient::Request.execute(method: :get,
                            url: "#{settings.protocol}://#{settings.case_service_host}:#{settings.case_service_port}/reports/types",
                            user: settings.security_user_name,
                            password: settings.security_user_password,
                            realm: settings.security_realm) do |response, _request, _result, &_block|
    case_report_types = JSON.parse(response) unless response.code == 204
    case_report_types.map { |report_type| report_type['reportClass'] = 'case' }
  end
  RestClient::Request.execute(method: :get,
                            url: "#{settings.protocol}://#{settings.action_exporter_host}:#{settings.action_exporter_port}/reports/types",
                            user: settings.security_user_name,
                            password: settings.security_user_password,
                            realm: settings.security_realm) do |response, _request, _result, &_block|
    action_report_types = JSON.parse(response) unless response.code == 204
    action_report_types.map { |report_type| report_type['reportClass'] = 'action-exporter' }
  end

  RestClient::Request.execute(method: :get,
                              url: "#{settings.protocol}://#{settings.sample_service_host}:#{settings.sample_service_port}/reports/types",
                              user: settings.security_user_name,
                              password: settings.security_user_password,
                              realm: settings.security_realm) do |response, _request, _result, &_block|

    sample_report_types = JSON.parse(response) unless response.code == 204
    sample_report_types.map { |report_type| report_type['reportClass'] = 'sample' }
  end

  report_types = case_report_types + action_exporter_report_types + action_report_types + collectionexercisesvc_report_types + sample_report_types
  report_types = report_types.sort_by{ |type| type['displayName']}.paginate(page: params[:page])
  erb :reports, locals: { title: 'Reports',
                          report_types: report_types }
end

get '/reports/:report_class/:report_type' do |report_class, report_type|
  authenticate!
  report_details = []
  error = 0
  host, port = host_and_port_for_report_class(report_class)

  RestClient::Request.execute(method: :get,
                            url: "#{settings.protocol}://#{host}:#{port}/reports/types/#{report_type.upcase}",
                            user: settings.security_user_name,
                            password: settings.security_user_password,
                            realm: settings.security_realm) do |response, _request, _result, &_block|
    report_details = JSON.parse(response).paginate(page: params[:page]) unless response.code == 204 || response.code == 400
    code = response.code
    if [200, 204].include?(code)
      erb :report_type, locals: { title: type_format(report_type),
                                  report_details: report_details,
                                  report_type: report_type,
                                  report_class: report_class }
    else
      erb :reports_errors, locals: { title: 'Error!',
                                     report_type: report_type,
                                     error: error }
    end
  end
end

get '/reports/download/:report_class/:report_id' do |report_class, report_id|
  authenticate!
  report_details = []
  host, port = host_and_port_for_report_class(report_class)

  RestClient::Request.execute(method: :get,
                            url: "#{settings.protocol}://#{host}:#{port}/reports/#{report_id}",
                            user: settings.security_user_name,
                            password: settings.security_user_password,
                            realm: settings.security_realm) do |response, _request, _result, &_block|
    report_details = JSON.parse(response) unless response.code == 204 || response.code == 400
  end
  t = Time.parse(report_details['createdDateTime'])
  t = t.localtime.strftime('%Y%m%d')
  attachment "#{type_format(report_details['reportType']).tr(' ', '_')}_#{t}.csv"
  report_details['contents']
end

get '/reports/view/:report_class/:report_id' do |report_class, report_id|
  authenticate!
  report_details = []
  error = 1
  host, port = host_and_port_for_report_class(report_class)

  RestClient::Request.execute(method: :get,
                              url: "#{settings.protocol}://#{host}:#{port}/reports/#{report_id}",
                              user: settings.security_user_name,
                              password: settings.security_user_password,
                              realm: settings.security_realm) do |response, _request, _result, &_block|    report_details = JSON.parse(response) unless response.code == 204 || response.code == 400
    code = response.code
    if code == 200
      contents = CSV.parse(report_details['contents'], headers: false).to_a
      erb :view_report, locals: { title: type_format(report_details['reportType']) + ' ' + report_details['createdDateTime'].to_report_date,
                                  report_date: report_details['createdDateTime'],
                                  contents: contents,
                                  report_type: report_details['reportType'],
                                  report_class: report_class }
    else
      erb :reports_errors, locals: { title: 'Error!',
                                     report_id: report_id,
                                     error: error }
    end
  end
end
