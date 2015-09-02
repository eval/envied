# Responsible for all string to type coercions.
class ENVied::Coercer
  # Coerce strings to specific type.
  #
  # @param string [String] the string to be coerced
  # @param type [#to_sym] the type to coerce to
  #
  # @example
  #   ENVied::Coercer.new.coerce('1', :Integer)
  #   # => 1
  #
  # @return [type] the coerced string.
  def coerce(string, type)
    unless supported_type?(type)
      raise ArgumentError, "#{type.inspect} is not supported type"
    end
    coerce_method_for(type.to_sym)[string]
  end

  def coerce_method_for(type)
    return nil unless supported_type?(type)
    coercer.method("to_#{type.downcase}")
  end

  def self.supported_types
    @supported_types ||= begin
      [:hash, :array, :time, :date, :symbol, :boolean, :integer, :string].sort
    end
  end

  # Whether or not Coercer can coerce strings to the provided type.
  #
  # @param type [#to_sym] the type (case insensitive)
  #
  # @example
  #   ENVied::Coercer.supported_type?('string')
  #   # => true
  #
  # @return [Boolean] whether type is supported.
  def self.supported_type?(type)
    supported_types.include?(type.to_sym.downcase)
  end

  def supported_type?(type)
    self.class.supported_type?(type)
  end

  def supported_types
    self.class.supported_types
  end

  def coercer
    @coercer ||= Coercible::Coercer.new[ENVied::Coercer::String]
  end

  def coerced?(value)
    !value.kind_of?(::String)
  end

  def coercible?(string, type)
    return false unless supported_type?(type)
    coerce(string, type)
    true
  rescue Coercible::UnsupportedCoercion
    false
  end
end
