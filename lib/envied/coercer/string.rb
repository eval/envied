require 'coercible'

class ENVied::Coercer::String < Coercible::Coercer::String
  def to_array(str)
    str.split(/(?<!\\),/).map{|i| i.gsub(/\\,/,',') }
  end

  def to_hash(str)
    require 'rack/utils'
    ::Rack::Utils.parse_query(str)
  end
end
