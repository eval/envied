class ENVied::Coercer::String < ENVied::Coercer::BaseType

  def parse
    if raw_value.respond_to?(:to_str)
      @value = raw_value.public_send(:to_str)
      @parsed = true
    end
  end

end
