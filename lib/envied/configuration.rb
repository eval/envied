class ENVied
  class Configuration
    attr_reader :current_group, :defaults_enabled, :coercer

    def initialize(options = {}, &block)
      @defaults_enabled = options.fetch(:enable_defaults, false)
      @coercer = options.fetch(:coercer, Coercer.new)
      instance_eval(&block) if block_given?
    end

    def self.load(options = {})
      envfile = File.expand_path('Envfile')
      new(options).tap do |v|
        v.instance_eval(File.read(envfile), envfile)
      end
    end

    def enable_defaults!(value = nil, &block)
      @defaults_enabled = (value.nil? ? block : value)
    end

    def defaults_enabled?
      @defaults_enabled.respond_to?(:call) ?
        @defaults_enabled.call :
        @defaults_enabled
    end

    def variable(name, type = :String, options = {})
      unless coercer.supported_type?(type)
        raise ArgumentError,
          "Variable type (of #{name}) should be one of #{coercer.supported_types}"
      end
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

end
