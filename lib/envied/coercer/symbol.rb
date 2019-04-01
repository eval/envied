class ENVied::Coercer::Symbol < ENVied::Coercer::BaseType

  def parse
    @value = raw_value.to_sym
    @parsed = true
  end

end
