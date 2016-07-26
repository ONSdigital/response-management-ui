require_relative 'constants'

class String
  include Constants

  def to_address_type
    case self
    when 'CE'
      'Communal Establishment'
    when 'HH'
      'Household'
    when 'I'
      'Individual'
    else
      '-'
    end
  end

  def to_date
    t = Time.parse(self)
    t.localtime.strftime(DATE_FORMAT)
  end

  # Naive conversion to title case.
  def to_title_case
    split.map(&:capitalize).join(' ')
  end
end