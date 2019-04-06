class ENVied::Variable
  attr_reader :name, :type, :group, :default

  def initialize(name, type, **options)
    @name = name.to_sym
    @type = type.to_sym
    @group = options.fetch(:group, :default).to_sym
    @default = options[:default]

    #if !@default.is_a? String
    #  raise ArgumentError, "Default values should be strings (variable #{@name})"
    #end
  end

  def default_value(*args)
    default.respond_to?(:call) ? default[*args] : default
  end

  def ==(other)
    self.class == other.class &&
      [name, type, group, default] == [other.name, other.type, other.group, other.default]
  end
end
