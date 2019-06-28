class ENVied
  class Configuration
    attr_reader :current_group, :defaults_enabled, :coercer

    def initialize(**options, &block)
      @coercer = options.fetch(:coercer, Coercer.new)
      @defaults_enabled = options.fetch(:enable_defaults, defaults_enabled_default)
      instance_eval(&block) if block_given?
    end

    def self.load(**options)
      envfile = File.expand_path('Envfile')
      new(options).tap do |v|
        v.instance_eval(File.read(envfile), envfile)
      end
    end

    def enable_defaults!(value = true, &block)
      default_values_deprecation
      @defaults_enabled = block_given? ? block.call : value
    end

    def defaults_enabled?
      @defaults_enabled.respond_to?(:call) ?
        @defaults_enabled.call :
        @defaults_enabled
    end

    def variable(name, type = :string, **options)
      unless coercer.supported_type?(type)
        raise ArgumentError, "#{type.inspect} is not a supported type. Should be one of #{coercer.supported_types}"
      end
      options[:group] = current_group if current_group
      variables << ENVied::Variable.new(name, type, options)
    end

    def group(*names, &block)
      names.each do |name|
        @current_group = name.to_sym
        yield
      end
    ensure
      @current_group = nil
    end

    def variables
      @variables ||= []
    end

    private

    def default_values_deprecation
      warning = "Default values will be removed in the next minor-release of ENVied (i.e. > v0.9). For more info see https://gitlab.com/envied/envied/tree/0-9-releases#defaults."
      if defined?(ActiveSupport::Deprecation)
        ActiveSupport::Deprecation.warn warning
      else
        $stderr.puts "DEPRECATION WARNING: #{warning}"
      end
    end

    def defaults_enabled_default
      if ENV['ENVIED_ENABLE_DEFAULTS'].nil?
        false
      else
        @coercer.coerce(ENV['ENVIED_ENABLE_DEFAULTS'], :boolean)
      end
    end
  end
end
