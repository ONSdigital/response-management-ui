require 'net/ldap'

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
    token = nil

    if entries && entries.any?
      token = entries.first.send(TOKEN_ATTRIBUTE.to_sym).first
    else
      puts 'failed'
    end

    token
  end
end
