require 'net/ldap'

UserEntry = Struct.new(:display_name, :token)

class LDAPConnection
  TOKEN_ATTRIBUTE = 'employeeNumber'

  def initialize(host, port, base)
    @host = host
    @port = port.to_i
    @base = base
  end

  def bind(username, password)
    ldap = Net::LDAP.new(host: @host, port: @port, base: @base)
    ldap.auth(@base, password)
    entries = ldap.bind_as(filter: "(cn=#{username})", password: password)
    user_entry = nil

    if entries && entries.any?
      display_name = entries.first.displayName.first
      token = entries.first.send(TOKEN_ATTRIBUTE.to_sym).first
      user_entry = UserEntry.new(display_name, token)
    else
      puts 'failed'
    end

    user_entry
  end
end
