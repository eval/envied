class ENVied::Coercer::BaseType

  attr_reader :value, :raw_value

  def initialize(raw_value)
    @raw_value = raw_value
    @parsed = false
  end

  def self.parse(raw_value)
    new(raw_value).tap(&:parse)
  end

  def parse
  end

  def parsed?
    @parsed
  end

  def failed?
    !parsed?
  end

end
