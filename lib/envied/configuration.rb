class ENVied
  class Configuration
    attr_reader :current_group, :defaults_enabled

    def initialize(options = {})
      @defaults_enabled = options.fetch(:enable_defaults, false)
    end

    def self.load
      new.tap do |v|
        v.instance_eval(File.read(File.expand_path('Envfile')))
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
