class ENVied::Coercer::ENViedString
  TRUE_VALUES = %w[1 on t true y yes].freeze
  FALSE_VALUES = %w[0 off f false n no].freeze
  BOOLEAN_MAP = (TRUE_VALUES.product([ true ]) + FALSE_VALUES.product([ false ])).to_h.freeze

  def to_array(str)
    str.split(/(?<!\\),/).map{|i| i.gsub(/\\,/,',') }
  end

  def to_boolean(str)
    BOOLEAN_MAP.fetch(str&.downcase) do
      raise_unsupported_coercion(str, __method__)
    end
  end

  def to_date(str)
    require 'date'
    ::Date.parse(str)
  rescue ArgumentError
    raise_unsupported_coercion(str, __method__)
  end

  def to_float(str)
    Float(str)
  rescue ArgumentError
    raise_unsupported_coercion(str, __method__)
  end

  def to_hash(str)
    require 'cgi'
    ::CGI.parse(str).map { |key, values| [key, values[0]] }.to_h
  end

  def to_string(str)
    if str.respond_to?(:to_str)
      str.public_send(:to_str)
    else
      raise_unsupported_coercion(str, __method__)
    end
  end

  def to_env(string)
    to_string(string)
  end

  def to_symbol(str)
    str.to_sym
  end

  def to_time(str)
    require 'time'
    ::Time.parse(str)
  rescue ArgumentError
    raise_unsupported_coercion(str, __method__)
  end

  def to_uri(str)
    require 'uri'
    ::URI.parse(str)
  end

  def to_integer(str)
    Integer(str)
  rescue ArgumentError
    raise_unsupported_coercion(str, __method__)
  end

  private

  def raise_unsupported_coercion(value, method)
    raise(
      ENVied::Coercer::UnsupportedCoercion,
      "#{self.class}##{method} doesn't know how to coerce #{value.inspect}"
    )
  end
end
