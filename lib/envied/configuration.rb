class ENVied
  class Configuration
    attr_reader :current_group, :coercer

    def initialize(options = {}, &block)
      @coercer = options.fetch(:coercer, Coercer.new)
      instance_eval(&block) if block_given?
    end

    def self.load(options = {})
      envfile = File.expand_path('Envfile')
      new(options).tap do |v|
        v.instance_eval(File.read(envfile), envfile)
      end
    end

    def variable(name, *args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      type = args.first || :string

      unless coercer.supported_type?(type)
        raise ArgumentError,
          "Variable type (of #{name}) should be one of #{coercer.supported_types}"
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
  end

end
