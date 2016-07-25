require 'rotp'

require_relative '../lib/core_ext/object'

class User
  attr_reader :user_id
  attr_reader :display_name
  attr_reader :groups


  def self.authenticate(ldap_connection, params = {})
    username = params[:username]
    password = params[:password]
    return nil if username.blank? || password.blank?

    user_entry = ldap_connection.authenticate(username, password)

    User.new(user_entry.user_id, user_entry.display_name, user_entry.token, user_entry.groups) unless user_entry.nil?
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
