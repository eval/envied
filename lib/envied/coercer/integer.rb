class ENVied::Coercer::Integer < ENVied::Coercer::BaseType

  def parse
    @value = Integer(raw_value)
  rescue ArgumentError
  else
    @parsed = true
  end

end
