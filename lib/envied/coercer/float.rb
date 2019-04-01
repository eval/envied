class ENVied::Coercer::Float < ENVied::Coercer::BaseType

  def parse
    @value = Float(raw_value)
    @parsed = true
  rescue ArgumentError
  end

end
