class ENVied::Type
  attr_reader :name

  def initialize(name, coercer)
    @name = name
    @coercer = coercer
  end

  def coerce(value)
    coercer.call(value)
  end

  def ==(other)
    self.class == other.class &&
      name == other.name &&
      coercer == other.coercer
  end

  protected

  attr_reader :coercer
end
