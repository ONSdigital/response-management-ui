def type_format(report_type)
  formatted_type = report_type.tr('_', ' ').split.map(&:capitalize).join(' ')
  formatted_type[1] = formatted_type[1].upcase if formatted_type[2] == ' '
  formatted_type
end

get '/reports' do
  authenticate!
  report_types = []

  RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/reports/types") do |response, _request, _result, &_block|
    report_types = JSON.parse(response).paginate(page: params[:page]) unless response.code == 204
  end

  erb :reports, locals: { title: 'Reports',
                          user: user_role,
                          report_types: report_types }
end

get '/reports/:report_type' do |report_type|
  authenticate!
  report_details = []
  error = 0

  RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/reports/types/#{report_type.upcase}") do |response, _request, _result, &_block|
    report_details = JSON.parse(response).paginate(page: params[:page]) unless response.code == 204 || response.code == 400

    if response.code == 200 || response.code == 204
      erb :report_type, locals: { title: type_format(report_type),
                                  user: user_role,
                                  report_details: report_details,
                                  report_type: report_type }
    else
      erb :reports_errors, locals: { title: 'Error!',
                                     user: user_role,
                                     report_type: report_type,
                                     error: error }
    end
  end
end

get '/reports/download/:report_id' do |report_id|
  authenticate!
  report_details = []

  RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/reports/#{report_id}") do |response, _request, _result, &_block|
    report_details = JSON.parse(response) unless response.code == 204 || response.code == 500
    t = Time.parse(report_details['createdDateTime'])
    t = t.localtime.strftime('%Y%m%d')
    attachment "#{type_format(report_details['reportType']).tr(' ', '_')}_#{t}.csv"
    report_details['contents']
  end
end

get '/reports/view/:report_id' do |report_id|
  authenticate!
  report_details = []
  error = 1

  RestClient.get("http://#{settings.case_service_host}:#{settings.case_service_port}/reports/#{report_id}") do |response, _request, _result, &_block|
    report_details = JSON.parse(response) unless response.code == 204 || response.code == 500
    if response.code == 200
      contents = CSV.parse(report_details['contents'], headers: false).to_a
      erb :view_report, locals: { title: type_format(report_details['reportType']) + ' ' + report_details['createdDateTime'].to_report_date,
                                  user: user_role,
                                  report_date: report_details['createdDateTime'],
                                  contents: contents,
                                  report_type: report_details['reportType'] }
    else
      erb :reports_errors, locals: { title: 'Error!',
                                     user: user_role,
                                     report_id: report_id,
                                     error: error }
    end
  end
end
