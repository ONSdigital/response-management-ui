require 'rotp'
require 'rest-client'

require_relative '../lib/core_ext/object'

class User
  attr_reader :user_id
  attr_reader :display_name
  attr_reader :groups

  def self.authenticate(clientuser, clientpass, oauth_server, params = {})
    username = params[:username]
    password = params[:password]
    return nil if username.blank? || password.blank?  

    response = RestClient::Request.new({ method: :post,
                                   url: oauth_server,
                                   user: clientuser,
                                   password: clientpass,
                                   payload: { grant_type: 'password',
                                              username: username,
                                              password: password }
                                  }).execute do |response, request, result|
                                    puts response
                                    puts response.code
    case response.code
      when 201
        user_entry = true
      else
        user_entry = false
      end
    end
  end

  def initialize(user_id, display_name, token, groups)
    @user_id      = user_id
    @display_name = display_name
    @token        = token
    @groups       = groups
  end

  def valid_code?(drift, params = {})
    code = params[:code]
    return false if code.blank?

    totp = ROTP::TOTP.new(@token)
    totp.verify_with_drift(code, drift)
  end
end
