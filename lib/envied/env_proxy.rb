class ENVied
  # Responsible for anything related to the ENV.
  class EnvProxy
    attr_reader :config, :coercer, :groups
    private :config, :coercer, :groups

    def initialize(config, **options)
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

    def [](name)
      coerce(variables_by_name[name.to_sym])
    end

    def has_key?(name)
      variables_by_name[name.to_sym]
    end

    def value_to_coerce(var)
      return env_value_of(var) unless env_value_of(var).nil?
    end

    private

    def coerce(var)
      coerced?(var) ?
        value_to_coerce(var) :
        coercer.coerce(value_to_coerce(var), var.type)
    end

    def coerced?(var)
      coercer.coerced?(value_to_coerce(var))
    end

    def coercible?(var)
      coercer.coercible?(value_to_coerce(var), var.type)
    end

    def env_value_of(var)
      ENV[var.name.to_s]
    end

    def missing?(var)
      value_to_coerce(var).nil?
    end

    def variables
      @variables ||= config.variables.select {|v| groups.include?(v.group) }
    end

    def variables_by_name
      @variables_by_name ||= variables.map {|v| [v.name, v] }.to_h
    end
  end
end
