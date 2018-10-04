require 'coercible'

# Responsible for all string to type coercions.
class ENVied::Coercer
  extend Forwardable

  SUPPORTED_TYPES = %i(hash array time date symbol boolean integer string uri float).freeze

  class << self
    def built_in_type?(type)
      SUPPORTED_TYPES.include?(type)
    end

    def custom_type?(type)
      custom_types.key?(type)
    end

    # Custom types container.
    #
    # @example
    #   ENVied::Coercer.custom_types[:json] =
    #     ENVied::Type.new(:json, ->(str) { JSON.parse(str) })
    #
    # @return
    def custom_types
      @custom_types ||= {}
    end

    def supported_types
      SUPPORTED_TYPES + custom_types.keys
    end

    # Whether or not Coercer can coerce strings to the provided type.
    #
    # @param type [#to_sym] the type (case insensitive)
    #
    # @example
    #   ENVied::Coercer.supported_type?('string')
    #   # => true
    #
    # @return [Hash] of type names and their definitions.
    def supported_type?(type)
      name = type.to_sym.downcase
      built_in_type?(name) || custom_type?(name)
    end
  end

  def_delegators :'self.class', :supported_type?, :supported_types, :custom_types

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
    if self.class.built_in_type?(type)
      coerce_method_for(type.to_sym)[string]
    elsif self.class.custom_type?(type)
      custom_types[type].coerce(string)
    else
      raise ArgumentError, "#{type.inspect} is not supported type"
    end
  end

  def coerce_method_for(type)
    return nil unless supported_type?(type)
    coercer.method("to_#{type.downcase}")
  end

  def coercer
    @coercer ||= Coercible::Coercer.new[ENViedString]
  end

  def coerced?(value)
    !value.kind_of?(String)
  end

  def coercible?(string, type)
    return false unless supported_type?(type)
    coerce(string, type)
    true
  rescue Coercible::UnsupportedCoercion
    false
  end
end
