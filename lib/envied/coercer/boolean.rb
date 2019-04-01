class ENVied::Coercer::Boolean < ENVied::Coercer::BaseType
  TRUE_VALUES = %w[1 on t true y yes].freeze
  FALSE_VALUES = %w[0 off f false n no].freeze
  BOOLEAN_MAP = (TRUE_VALUES.product([ true ]) + FALSE_VALUES.product([ false ])).to_h.freeze

  def parse
    @parsed = true
    @value = BOOLEAN_MAP.fetch(raw_value&.downcase) do
      @parsed = false
    end
  end

end
