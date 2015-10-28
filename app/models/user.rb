require 'rotp'

class User
  attr_reader :display_name

  def self.authenticate(ldap_connection, params = {})
    username = params[:username]
    password = params[:password]
    return nil if username.blank? || password.blank?

    user_entry = ldap_connection.bind(username, password)
    User.new(user_entry.display_name, user_entry.token) unless user_entry.nil?
  end

  def initialize(display_name, token)
    @display_name = display_name
    @token        = token
  end

  def valid_code?(drift, params = {})
    code = params[:code]
    return false if code.blank?

    totp = ROTP::TOTP.new(@token)
    totp.verify_with_drift(code, drift)
  end
end
