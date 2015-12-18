require 'net/ldap'

UserEntry = Struct.new(:display_name, :token)

class LDAPConnection
  TOKEN_ATTRIBUTE = 'employeeNumber'

  def initialize(host, port, base, groups, logger)
    @@host   = host
    @@port   = port.to_i
    @@base   = base
    @@groups = groups
    @@logger = logger
  end

  def bind(username, password)
    @ldap = Net::LDAP.new(host: @@host, port: @@port, base: @@base)
    @ldap.auth(@@base, password)
    entries = @ldap.bind_as(filter: "(cn=#{username})", password: password)
    user_entry = nil

    if entries && entries.any?
      @@logger.info "LDAP bind succeeded for '#{username}'"
      return nil unless group_member?(@@groups['users'], username)

      display_name = entries.first.displayName.first
      token = entries.first.send(TOKEN_ATTRIBUTE.to_sym).first
      user_entry = UserEntry.new(display_name, token)
    else
      @@logger.info "LDAP bind failed for '#{username}'"
    end

    user_entry
  end

  private

  def group_member?(group, username)
    @@logger.info group
    true
  end
end
