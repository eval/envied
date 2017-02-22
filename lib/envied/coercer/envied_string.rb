require 'coercible'

class ENVied::Coercer::ENViedString < Coercible::Coercer::String
  def to_array(str)
    str.split(/(?<!\\),/).map{|i| i.gsub(/\\,/,',') }
  end

  def to_hash(str)
    require 'rack/utils'
    ::Rack::Utils.parse_query(str)
  end

  def to_uri(str)
    require 'uri'
    ::URI.parse(str)
  end
end
