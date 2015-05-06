class ENVied
  class Configuration
    attr_reader :current_group, :current_conditional, :defaults_enabled, :coercer

    def initialize(options = {}, &block)
      @coercer = options.fetch(:coercer, Coercer.new)
      @defaults_enabled = options.fetch(:enable_defaults, defaults_enabled_default)
      instance_eval(&block) if block_given?
    end

    def defaults_enabled_default
      if ENV['ENVIED_ENABLE_DEFAULTS'].nil?
        false
      else
        @coercer.coerce(ENV['ENVIED_ENABLE_DEFAULTS'], :boolean)
      end
    end

    def self.load(options = {})
      envfile = File.expand_path('Envfile')
      new(options).tap do |v|
        v.instance_eval(File.read(envfile), envfile)
      end
    end

    def enable_defaults!(value = true, &block)
      @defaults_enabled = block_given? ? block.call : value
    end

    def defaults_enabled?
      @defaults_enabled.respond_to?(:call) ?
        @defaults_enabled.call :
        @defaults_enabled
    end

    def variable(name, *args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      type = args.first || :string

      unless coercer.supported_type?(type)
        raise ArgumentError,
          "Variable type (of #{name}) should be one of #{coercer.supported_types}"
      end
      options[:group] = current_group if current_group
      if current_conditional
        options[:conditional] = current_conditional
        variables << current_conditional
      end
      variables << ENVied::Variable.new(name, type, options)
    end

    def group(name, &block)
      @current_group = name.to_sym
      yield
    ensure
      @current_group = nil
    end

    def conditional(name, *args, &block)
      options = args.last.is_a?(Hash) ? args.pop : {}
      type = args.first || :boolean
      unless coercer.supported_type?(type)
        raise ArgumentError,
          "Variable type (of #{name}) should be one of #{coercer.supported_types}"
      end
      @current_conditional = ENVied::Variable.new(name.to_sym, type, options)
      yield
    ensure
      @current_conditional = nil
    end

    def variables
      @variables ||= []
    end
  end

end
