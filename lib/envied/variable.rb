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
    if !@default.nil? && !@default.respond_to?(:call) && !@default.is_a?(String)
      deprecate_non_string_default
    end
  end

  def default_value(*args)
    if default.respond_to?(:call)
      default[*args].tap do |value|
        deprecate_non_string_default if !value.nil? && !value.is_a?(String)
      end
    else
      default
    end
  end

  def ==(other)
    self.class == other.class &&
      [name, type, group, default] == [other.name, other.type, other.group, other.default]
  end

  private

  def deprecate_non_string_default
    warn "DEPRECATION WARNING: Using a non-string default value, will not be supported in a future release and will raise an error. Specify default values as a string to match how it would be set as an environment variable. For example, #{example_message}"
  end

  def example_message
    case type
    when :array
      "with a `#{type.inspect}` type, use `default: \"1,2,3\"` format instead."
    when :boolean
      "with a `#{type.inspect}` type, use `default: \"true\"` format instead."
    when :date
      "with a `#{type.inspect}` type, use `default: \"2019-03-23\"` format instead."
    when :float
      "with a `#{type.inspect}` type, use `default: \"1.23\"` format instead."
    when :hash
      "with a `#{type.inspect}` type, use `default: \"a=1&b=2&c=3\"` format instead."
    when :integer
      "with a `#{type.inspect}` type, use `default: \"1\"` format instead."
    when :symbol
      "with a `#{type.inspect}` type, use `default: \"my_symbol\"` format instead."
    when :time
      "with a `#{type.inspect}` type, use `default: \"2019-03-23 14:30:55\"` format instead."
    when :uri
      "with a `#{type.inspect}` type, use `default: \"https://github.com/\"` format instead."
    end
  end
end
