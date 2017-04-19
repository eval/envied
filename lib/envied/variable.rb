class ENVied::Variable
  attr_reader :name, :type, :group, :sample_value, :sample_comment

  def initialize(name, type, options = {})
    @name = name.to_sym
    @type = type.to_sym
    @group = options.fetch(:group, :default).to_sym
    @sample_value, @sample_comment = *Array(options[:sample])
    validate_sample!
  end

  def ==(other)
    self.class == other.class &&
      [name, type, group] == [other.name, other.type, other.group]
  end

  def validate_sample!
    if !sample_value.nil? && !sample_value.is_a?(String)
      raise ArgumentError, "Sample values should always be strings (given #{sample_value.inspect} for variable #{name})"
    end
  end
end
