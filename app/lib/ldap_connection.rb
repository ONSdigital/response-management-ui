require 'net/ldap'

class LDAPConnection
  TOKEN_ATTRIBUTE = 'employeeNumber'
  TREE_BASE       = 'dc=ctp,dc=ons,dc=gov,dc=uk'

  def initialize(host, port)
    @host = host
    @port = port
  end

  def bind(username, password)
    ldap = Net::LDAP.new(host: @host, port: @port,
                         auth: { method: :simple,
                                 username: "cn=#{username},ou=Users,#{TREE_BASE}",
                                 password: password })

    token = nil
    filter = Net::LDAP::Filter.eq('cn', username)
    ldap.search(base: TREE_BASE, filter: filter, attributes: [TOKEN_ATTRIBUTE]) do |entry|
      token = entry.send(TOKEN_ATTRIBUTE.to_sym).first
    end
    token
  end
end
