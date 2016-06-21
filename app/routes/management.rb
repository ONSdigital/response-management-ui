require 'ctp-common'

module Beyond
  class Gateway
    TIME_FORMAT = '%e %b %Y %H:%M GMT'

    def initialize(json)
      @active = json['active']
      @polled = json['laststamp']
      @updated = json['higheststamp']
    end

    def active?
      @active
    end

    def polled
      DateTime.parse(@polled).to_time.strftime(TIME_FORMAT)
    end

    def updated
      DateTime.parse(@updated).to_time.strftime(TIME_FORMAT)
    end
  end

  module Routes
    class Management < Base

      # Management home page.
      get '/manage' do
        authenticate!
        erb :manage, locals: { title: 'Manage' }
      end

      # Get all escalated cases.
      get '/manage/escalated/:escalatetype' do |escalatetype|
        escalated = []
        authenticate!
        type = "#{escalatetype.capitalize}Escalation"

        RestClient.get("http://#{settings.action_service_host}:#{settings.action_service_port}/actions?actiontype=#{type}&state=PENDING") do |response, _request, _result, &_block|
          escalated = JSON.parse(response).paginate(page: params[:page]) unless response.code == 204
        end

        erb :escalated_cases, locals: { title: "View Escalated #{escalatetype.capitalize} Cases", escalated: escalated }
      end
    end
  end
end
