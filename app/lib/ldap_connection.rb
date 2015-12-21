require 'net/ldap'

UserEntry = Struct.new(:display_name, :token, :admin)

class LDAPConnection
  def initialize(host, port, base, groups, logger)
    @@host   = host
    @@port   = port.to_i
    @@base   = base
    @@groups = groups
    @@logger = logger
  end

  def authenticate(username, password)
    user_entry = nil
    auth = { method: :simple, username: username, password: password }

    # TODO Auth seems to accept any password.
    Net::LDAP.open(host: @@host, port: @@port, base: @@base, auth: auth) do |ldap|
      # unless ldap.bind
      #   @@logger.error "LDAP authentication failed for '#{username}'"
      #   return nil
      # end

      @@logger.info "LDAP authentication succeeded for '#{username}'"
      user_entry = entry_for(username, ldap) || nil

      # The user must be a member of at least the "<zone>-users" group for authentication to succeed.
      users_group = @@groups['users']
      unless group_member?(users_group, username, ldap)
        @@logger.error "LDAP authentication failed: '#{username}' is not a member of the '#{users_group}' group"
        return nil
      end

      # See if the user is also a member of the "<zone>-admins" group.
      user_entry.admin = group_member?(@@groups['admins'], username, ldap)
    end

    user_entry
  end

  private

  # Returns the LDAP directory entry for a user.
  def entry_for(username, ldap)
    filter     = Net::LDAP::Filter.construct("(cn=#{username})")
    attributes = ['displayName', 'employeeNumber'] # employeeNumber is used to store the 2FA token.
    user_entry = nil

    succeeded = ldap.search(filter: filter, attributes: attributes, return_result: false) do |entry|
      user_entry = UserEntry.new(entry.displayName.first, entry.employeeNumber.first)
    end

    unless succeeded
      result = ldap.get_operation_result
      @@logger.error "Error searching the LDAP directory using filter '#{filter}': #{result.message} (#{result.code})"
    end

    user_entry
  end

  # Returns whether a user is a member of a group.
  def group_member?(group, username, ldap)
    filter     = Net::LDAP::Filter.construct("(&(cn=#{group})(memberUid=#{username}))")
    attributes = ['cn']
    group_cn   = nil

    succeeded = ldap.search(filter: filter, attributes: attributes, return_result: false) do |entry|
      group_cn = entry.cn.first
    end

    unless succeeded
      result = ldap.get_operation_result
      @@logger.error "Error searching the LDAP directory using filter '#{filter}': #{result.message} (#{result.code})"
    end

    group_cn == group
  end
end
