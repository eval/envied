require 'virtus'

class ENVied
  class Configuration
    include Virtus.model

    def self.variable(name, type = :String, options = {})
      options = { strict: true }.merge(options)
      attribute(name, type, options)
    end

    class << self
      attr_accessor :enable_defaults
      alias_method :defaults_enabled?, :enable_defaults
    end

    def self.enable_defaults
      @enable_defaults.respond_to?(:call) ?
        @enable_defaults.call :
        @enable_defaults
    end
  end

  def self.configuration(options = {}, &block)
    if block_given?
      @configuration = Class.new(Configuration)
      options.each{|k, v| @configuration.public_send("#{k}=", v) }
      @configuration.instance_eval(&block)
    end
    @configuration ||= Class.new(Configuration)
  end
  class << self
    alias_method :configure, :configuration
  end

  def self.require!
    @instance = nil
    error_on_missing_variables!
    error_on_uncoercible_variables!

    # TODO move this?
    @instance = configuration.new(ENV.to_hash)
  end

  def self.error_on_missing_variables!
    if missing_variable_names.any?
      raise "Please set the following ENV-variables: #{missing_variable_names.sort.join(',')}"
    end
  end

  def self.error_on_uncoercible_variables!
    if non_coercible_variables.any?
      single_error = "ENV['%{name}'] ('%{value}' can't be coerced to %{type})"
      errors = non_coercible_variables.map do |v|
        var_type = v.type.to_s.split("::").last
        single_error % { name: v.name, value: env_value_or_default(v), type: var_type }
      end.join ", "

      raise "Some ENV-variables are not coercible: #{errors}"
    end
  end

  def self.env_value(variable)
    ENV[variable.name.to_s]
  end

  def self.env_value_or_default(variable)
    env_value(variable) || default_value(variable)
  end

  # Yields the assigned default for the variable.
  # When defaults are disabled, nil is returned.
  def self.default_value(variable)
    defaults_enabled? ? variable.default_value.value : nil
  end

  # A list of all configured variable names.
  #
  # @example
  #   ENVied.configured_variable_names
  #   # => [:DATABASE_URL]
  #
  # @return [Array<Symbol>] the list of variable names
  def self.configured_variable_names
    configured_variables.map(&:name).map(&:to_sym)
  end

  def self.configured_variables
    configuration.attribute_set.dup
  end

  def self.provided_variable_names
    ENV.keys.map(&:to_sym)
  end

  def self.non_coercible_variables
    configured_variables.reject(&method(:variable_coercible?))
  end

  def self.variable_coercible?(variable)
    var_value = env_value_or_default(variable)
    return true if var_value.respond_to?(:call)

    variable.coerce var_value
  rescue Virtus::CoercionError
    return false
  end

  def self.missing_variable_names
    unprovided = configured_variable_names - provided_variable_names
    unprovided -= names_of_variables_with_defaults if defaults_enabled?
    unprovided
  end

  def self.names_of_variables_with_defaults
    variables_with_defaults.map(&:name).map(&:to_sym)
  end

  def self.variables_with_defaults
    configured_variables.map do |v|
      v unless v.default_value.value.nil?
    end.compact
  end

  def self.defaults_enabled?
    configuration.defaults_enabled?
  end

  def self.method_missing(method, *args, &block)
    respond_to_missing?(method) ? @instance.public_send(method, *args, &block) : super
  end

  def self.respond_to_missing?(method, include_private = false)
    @instance.respond_to?(method) || super
  end
end
