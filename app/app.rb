require 'rack/etag'
require 'rack/conditionalget'
require 'rack/deflater'

require_relative './routes/base'
require_relative './routes/frame_service'
require_relative './routes/follow_up_service'
require_relative './routes/management'
require_relative './routes/helpline_mi'

# Open up various built-in classes to add new convenience methods.
class Object

  # An object is blank if it's false, empty, or a whitespace string. For example, '', ' ', nil, [], and {} are all blank.
  def blank?
    respond_to?(:empty?) ? !!empty? : !self
  end

  # An object is present if it's not blank.
  def present?
    !blank?
  end
end

class Date
  def self.string_to_epoch_time(str)
    DateTime.parse(str).to_time.utc.to_i
  end
end

class Integer
  def to_comma_formatted
    to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, '\\1,')
  end

  def to_date(time: true)
    if time
      Time.at(self / 1000).utc.strftime('%e %b %Y %H:%M')
    else
      Time.at(self / 1000).utc.strftime('%e %b %Y')
    end
  end

  def to_hours
    Time.at(self / 1000).utc.strftime('%H')
  end

  def to_minutes
    Time.at(self / 1000).utc.strftime('%M')
  end
end

class Fixnum

  # Friendly form statuses.
  def to_form_status
    case self
    when 0
      'Not dispatched'
    when 1
      'Dispatched'
    else
      '-'
    end
  end
end

class String
  def to_date
    t = Time.parse(self)
    t.strftime('%e %b %Y %H:%M')
  end

  # Friendly form types.
  def to_form_type
    case self
    when '02'
      'Household Welsh'
    when '01'
      'Household English'
    when '04'
      'Individual'
    else
      '-'
    end
  end

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

  # Insert a space after the area code.
  def to_phone_number
    insert(5, ' ') if self.present?
  end

  # Naive conversion to title case.
  def to_title_case
    split.map(&:capitalize).join(' ')
  end
end

# Swallow NoMethodError when the receiver is nil.
class NilClass
  def to_phone_number
    ''
  end

  def to_title_case
    ''
  end
end

module Beyond
  class App < Sinatra::Application
    use Routes::Base
    use Routes::FrameService
    use Routes::FollowUpService
    use Routes::Management
    use Routes::HelplineMI
  end
end
