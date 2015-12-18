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
    filter = Net::LDAP::Filter.construct("(&(cn=#{group})(memberUid=#{username}))")
    puts filter
    @ldap.search(filter: filter) do |entry|
      entry.each do |attribute, values|
        puts "   #{attribute}:"
          values.each do |value|
            puts "      --->#{value}"
        end
      end
    end
    puts @ldap.get_operation_result
    false
  end
end
