require 'rotp'

class User
  attr_reader :name

  def self.authenticate(ldap_connection, params = {})
    username = params[:username]
    password = params[:password]
    return nil if username.blank? || password.blank?

    token = ldap_connection.bind(username, password)
    User.new(username, token) unless token.nil?
  end

  def initialize(username, token)
    @name  = username.to_title_case
    @token = token
  end

  def valid_code?(drift, params = {})
    code = params[:code]
    return false if code.blank?

    totp = ROTP::TOTP.new(@token)
    totp.verify_with_drift(code, drift)
  end
end
