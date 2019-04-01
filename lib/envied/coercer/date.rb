class ENVied::Coercer::Date < ENVied::Coercer::BaseType

  def parse
    require 'date'
    @value = ::Date.parse(raw_value)
    @parsed = true
  rescue ArgumentError, TypeError
  end

end
