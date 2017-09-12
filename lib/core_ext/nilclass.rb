# frozen_string_literal: true

# Swallow NoMethodError when the receiver is nil.
class NilClass
  def to_title_case
    ''
  end
end
