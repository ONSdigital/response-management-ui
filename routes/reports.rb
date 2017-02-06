def type_format(report_type)
  formatted_type = report_type.tr('_', ' ').split.map(&:capitalize).join(' ')
  formatted_type[1] = formatted_type[1].upcase if formatted_type[2] == ' '
  formatted_type
end

get '/reports' do
  authenticate!
  case_report_types = []
  action_report_types = []
  RestClient.get("#{settings.protocol}://#{settings.case_service_host}:#{settings.case_service_port}/reports/types") do |response, _request, _result, &_block|
    case_report_types = JSON.parse(response) unless response.code == 204
    (0..case_report_types.size - 1).each do |i|
      case_report_types[i]['reportClass'] = 'case'
    end
  end
  RestClient::Request.execute(method: :get,
                              url: "#{settings.protocol}://#{settings.action_exporter_host}:#{settings.action_exporter_port}/reports/types",
                              user: settings.action_exporter_user,
                              password: settings.action_exporter_password) do |response, _request, _result, &_block|
    action_report_types = JSON.parse(response) unless response.code == 204
    url = '/'
    (0..action_report_types.size - 1).each do |i|
      action_report_types[i]['reportClass'] = 'action'
    end
  end
  report_types = case_report_types + action_report_types
  report_types = report_types.paginate(page: params[:page])
  erb :reports, locals: { title: 'Reports',
                          user: user_role,
                          report_types: report_types }
end

get '/reports/:report_class/:report_type' do |report_class, report_type|
  authenticate!
  report_details = []
  error = 0
  code = 0
  host = settings.report_hosts[report_class]
  port = settings.report_ports[report_class]
  auth = settings.report_auth[report_class]

  RestClient::Request.execute(method: :get,
                              url: "#{settings.protocol}://#{host}:#{port}/reports/types/#{report_type.upcase}",
                              user: settings.action_exporter_user,
                              password: settings.action_exporter_password) do |response, _request, _result, &_block|
    report_details = JSON.parse(response).paginate(page: params[:page]) unless response.code == 204 || response.code == 400
    code = response.code
  end
  if code == 200 || code == 204
    erb :report_type, locals: { title: type_format(report_type),
                                user: user_role,
                                report_details: report_details,
                                report_type: report_type,
                                report_class: report_class }
  else
    erb :reports_errors, locals: { title: 'Error!',
                                   user: user_role,
                                   report_type: report_type,
                                   error: error }
  end
end

get '/reports/download/:report_class/:report_id' do |report_class, report_id|
  authenticate!
  report_details = []
  host = settings.report_hosts[report_class]
  port = settings.report_ports[report_class]

  RestClient::Request.execute(method: :get,
                              url: "#{settings.protocol}://#{host}:#{port}/reports/#{report_id}",
                              user: settings.action_exporter_user,
                              password: settings.action_exporter_password) do |response, _request, _result, &_block|
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
  host = settings.report_hosts[report_class]
  port = settings.report_ports[report_class]
  code = 0
  RestClient::Request.execute(method: :get,
                              url: "#{settings.protocol}://#{host}:#{port}/reports/#{report_id}",
                              user: settings.action_exporter_user,
                              password: settings.action_exporter_password) do |response, _request, _result, &_block|
    report_details = JSON.parse(response) unless response.code == 204 || response.code == 400
    code = response.code
  end
  if code == 200
    contents = CSV.parse(report_details['contents'], headers: false).to_a
    erb :view_report, locals: { title: type_format(report_details['reportType']) + ' ' + report_details['createdDateTime'].to_report_date,
                                user: user_role,
                                report_date: report_details['createdDateTime'],
                                contents: contents,
                                report_type: report_details['reportType'],
                                report_class: report_class }
  else
    erb :reports_errors, locals: { title: 'Error!',
                                   user: user_role,
                                   report_id: report_id,
                                   error: error }
  end
end
