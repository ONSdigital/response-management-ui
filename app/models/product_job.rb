class ProductJob

  attr_reader :code
  attr_reader :state
  attr_reader :date
  attr_reader :information
  attr_reader :type

  def initialize(code, state, date, information, type)
    @code = code
    @state = state
    @date = DateTime.parse(date)
    @information = information
    @type = type
  end

  def <=>(other)
    code == other.code ? other.date <=> date : code <=> other.code
  end

end
