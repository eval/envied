# 
class ENVied
  class Configuration
    attr_reader :current_group

    def self.load
      new.tap do |v|
        v.instance_eval(File.read(File.expand_path('Envfile')))
      end
    end

    def variable(name, type = :String, options = {})
      options[:group] = current_group if current_group
      variables << ENVied::Variable.new(name, type, options)
    end

    def group(name, &block)
      @current_group = name.to_sym
      yield
    ensure
      @current_group = nil
    end

    def variables
      @variables ||= []
    end
  end

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
      variables.reject(&method(:coercible?))
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
      variables_by_name[name.to_sym]
    end

    def env_value_of(var)
      ENV[var.name.to_s]
    end

    def coerce(var)
      coercer.coerce(env_value_of(var), var.type)
    end

    def coercible?(var)
      coercer.coercible?(env_value_of(var), var.type)
    end

    def missing?(var)
      !ENV.has_key?(var.name.to_s)
    end
  end
end
