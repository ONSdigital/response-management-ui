require 'pg'
require_relative '../models/response_generator'
require_relative '../models/product_job'

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
        erb :manage, locals: { title: 'Manage' }
      end

      # Get all regions.
      get '/manage/regions/?' do
        regions = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/regions")).paginate(page: params[:page])
        erb :manage_regions, locals: { title: 'Survey Access Token Management: Regions', regions: regions }
      end

      # Get all LAs for the selected region.
      get '/manage/regions/:region_code/las/?' do |region_code|
        local_authorities = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/lads?regionid=#{region_code}")).paginate(page: params[:page])
        erb :manage_local_authorities, locals: { title: "Survey Access Token Management: Local Authorities for Region #{region_code}",
                                                 region_code: region_code,
                                                 local_authorities: local_authorities }
      end

      # Get all caseloads and associated unactivated questionnaire counts for the selected LA.
      get '/manage/regions/:region_code/las/:local_authority_code/caseloads' do |region_code, local_authority_code|
        caseloads = JSON.parse(RestClient.get("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/caseloads?ladid=#{local_authority_code}&questionnairecounts=true")).paginate(page: params[:page])
        erb :manage_caseloads, locals: { title: "Survey Access Token Management: Caseloads for LA #{local_authority_code}",
                                         region_code: region_code,
                                         local_authority_code: local_authority_code,
                                         caseloads: caseloads }
      end

      get '/manage/responsegenerator/?' do
        rg = ResponseGenerator.new
        erb :manage_response_generator, locals: { title: 'Response Generator Control', response_generator: rg }
      end

      post '/manage/responsegenerator/?' do
        rg = ResponseGenerator.new
        rg.active = params['activeValue']
        rg.responses_per_minute = params['responses_per_minuteValue']
        rg.run_until = Date.today.to_s + ' ' + params['run_untilValue']
        rg.filter = params['filterName']

        begin
          result = rg.save!
          unless result.nil?
            flash[:notice] = 'Successfully reconfigured the Response Generator.'
          end
        rescue PG::Error => err
          flash[:error] = "Unable to reconfigure the Response Generator (#{err})"
        end

        redirect '/manage/responsegenerator'
      end

      # Activate the questionnaires within the selected caseload.
      put '/manage/regions/:region_code/las/:local_authority_code/caseloads/:caseload_code' do |region_code, local_authority_code, caseload_code|
        RestClient.put("http://#{settings.frame_service_host}:#{settings.frame_service_port}/frameservice/caseloads?ladid=#{local_authority_code}&caseload=#{caseload_code}",
                       {}.to_json, content_type: :json, accept: :json) do |response, _request, _result, &_block|
          if response.code == 200
            flash[:notice] = "Activating caseload #{caseload_code}."
          else
            flash[:error] = "Unable to activate caseload #{caseload_code} (HTTP #{response.code} received)."
          end
        end

        caseloads_url = "/manage/regions/#{region_code}/las/#{local_authority_code}/caseloads"
        caseloads_url += "?page=#{params[:page]}" if params[:page].present?
        redirect caseloads_url
      end

      # Present a form for issuing a Drools command.
      ['/drools/?', '/manage/drools?'].each do |path|
        get path do
          erb :drools, locals: { title: 'Run Drools Rules' }
        end
      end

      # Issue a Drools command.
      post '/manage/drools' do
        command = params[:command]
        filter_code = params[:factfiltercode]
        RestClient.post("http://#{settings.follow_up_service_host}:#{settings.follow_up_service_port}/FollowUpService/IssueDroolsCommand",
                        { commandName: command, factFilterCode: filter_code }.to_json, content_type: :json, accept: :json) do |response, _request, _result, &_block|
          if response.code == 200
            flash[:notice] = "Successfully issued Drools command for Ruleset #{command} and LA Code #{filter_code}."
          else
            flash[:notice] = "Unable to issue Drools command (HTTP #{response.code} received)."
          end
        end

        redirect '/manage/drools'
      end

      # Get information about the Redmine gateway for follow-ups.
      ['/gateway/?', '/manage/gateway/?'].each do |path|
        get path do
          gateway = Gateway.new(JSON.parse(RestClient.get("http://#{settings.follow_up_service_host}:#{settings.follow_up_service_port}/FollowUpService/GatewayInfo")))
          erb :gateway, locals: { title: 'Redmine Gateway Status', gateway: gateway }
        end
      end

      # Toggle the started/stopped state of the Redmine gateway for follow-ups.
      post '/manage/gateway' do
        active = !(params[:active] == 'true') ? true : false

        # A date has to be passed for higheststamp and last stamp but it's not actually used.
        epoch = '1970-01-01T00:00:00Z'
        RestClient.put("http://#{settings.follow_up_service_host}:#{settings.follow_up_service_port}/FollowUpService/GatewayInfo",
                       { active: active,
                         higheststamp: epoch,
                         laststamp: epoch }.to_json, content_type: :json, accept: :json) do |response, _request, _result, &_block|
          if response.code == 200
            flash[:notice] = "#{(active) ? 'Started' : 'Stopped'} polling the gateway."
          else
            flash[:notice] = "Unable to #{(active) ? 'start' : 'stop'} polling the gateway (HTTP #{response.code} received)."
          end
        end

        redirect '/manage/gateway'
      end

      # Manage Products screen
      get '/manage/products/?' do

        # Get list of available products
        products = JSON.parse(RestClient.get("http://#{settings.product_service_host}:#{settings.product_service_port}/productservice/products"))

        # Get list of in flight product Jobs with status information
        all_jobs = JSON.parse(RestClient.get("http://#{settings.product_service_host}:#{settings.product_service_port}/productservice/products/jobs"))

        product_jobs = []
        all_jobs.each do |job|
          product_jobs << ProductJob.new(job['code'], job['state'], job['timestamp'], job['data'], job['type'])
        end

        product_jobs.sort!
        erb :manage_products, locals: { title: 'Manage Products', products: products, product_jobs: product_jobs.paginate(page: params[:page]) }
      end

      post '/manage/manageproducts' do
        product = params[:product]
        action = params[:productAction]

        RestClient.post("http://#{settings.product_service_host}:#{settings.product_service_port}/productservice/products/jobs",
                        { code: product, type: action }.to_json, content_type: :json, accept: :json) do |response, _request, _result, &_block|
          if response.code == 200
            flash[:notice] = "Successfully created #{action} job for product #{product}"
          else
            flash[:notice] = "Unable to issue job creation request (HTTP #{response.code} received)."
          end
        end

        redirect '/manage/products'
      end
    end
  end
end
