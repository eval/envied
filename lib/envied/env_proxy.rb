class ENVied
  # Responsible for anything related to the ENV.
  class EnvProxy
    attr_reader :config, :coercer, :groups

    def initialize(config, options = {})
      @config = config
      @coercer = options.fetch(:coercer, ENVied::Coercer.new)
      @groups = options.fetch(:groups, [])
    end

    def missing_variables
      variables.select(&method(:missing?))
    end

    def uncoercible_variables
      variables.reject(&method(:coerced?)).reject(&method(:coercible?))
    end

    def variables
      @variables ||= begin
        config.variables.select {|v| groups.include?(v.group) }
      end
    end

    def variables_by_name
      Hash[variables.map {|v| [v.name, v] }]
    end

    def [](name)
      coerce(variables_by_name[name.to_sym])
    end

    def has_key?(name)
      variable = variables_by_name[name.to_sym]
      return unless variable
      return variable unless variable.conditional
      coerce(variable.conditional)
    end

    def env_value_of(var)
      ENV[var.name.to_s]
    end

    def default_value_of(var)
      var.default_value(ENVied, var)
    end

    def value_to_coerce(var)
      return env_value_of(var) unless env_value_of(var).nil?
      config.defaults_enabled? ? default_value_of(var) : nil
    end

    def coerce(var)
      coerced?(var) ?
        value_to_coerce(var) :
        coercer.coerce(value_to_coerce(var), var.type)
    end

    def coercible?(var)
      coercer.coercible?(value_to_coerce(var), var.type)
    end

    def missing?(var)
      return value_to_coerce(var).nil? unless var.conditional
      coerce(var.conditional)
    end

    def coerced?(var)
      coercer.coerced?(value_to_coerce(var))
    end
  end
end
