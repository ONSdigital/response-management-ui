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
      get '/manage/escalated' do
        authenticate!
        regions = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/regions")).paginate(page: params[:page])
        erb :escalated, locals: { title: 'View Escalated Cases' }
      end

    end
  end
end
