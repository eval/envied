require 'coercible'

class ENVied::Coercer::ENViedString < Coercible::Coercer::String
  def to_array(str)
    str.split(/(?<!\\),/).map{|i| i.gsub(/\\,/,',') }
  end

  def to_hash(str)
    require 'cgi'
    ::CGI.parse(str).map { |key, values| [key, values[0]] }.to_h
  end

  def to_uri(str)
    require 'uri'
    ::URI.parse(str)
  end

  def to_uri_with_scheme(str)
    result = to_uri(str)
    result.scheme.nil? ? raise_unsupported_coercion(str, __method__) : result
  end

  def to_integer(str)
    Integer(str)
  rescue ArgumentError
    raise_unsupported_coercion(str, __method__)
  end
end
