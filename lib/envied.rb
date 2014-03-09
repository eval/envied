class ENVied
  VERSION = "0.0.2"
  module Configurable
    require 'virtus'

    class VariableError < StandardError
      attr_reader :variable
      def initialize(variable)
        @variable = variable
      end

      def variable_type
        variable.type.to_s.split("::").last
      end
    end

    class VariableMissingError < VariableError
      def message
        "Please provide ENV['#{variable.name.to_s.upcase}'] of type #{variable_type}"
      end
    end

    class VariableTypeError < VariableError
      def message
        "ENV['#{variable.name.to_s.upcase}'] should be of type #{variable_type}"
      end
    end

    def self.included(base)
      base.class_eval do
        include Virtus.model
      end
      base.extend ClassMethods
    end

    module ClassMethods
      # Creates a configuration instance from env.
      #
      # Will raise VariableMissingError for variables not present in ENV.
      #
      # Will raise VariableTypeError for variables whose ENV-value can't be coerced to the configured type.
      #
      # @param env [Hash] the env
      def parse_env(env)
        atts = attribute_set.map(&:name).each_with_object({}) do |name, result|
          @variable = attribute_set[name]
          unless result[name] = env[name.to_s] || env[name.to_s.upcase]
            raise VariableMissingError, @variable
          end
        end

        new(atts)
      rescue Virtus::CoercionError => e
        raise VariableTypeError, @variable
      end

      def variable(name, type = :String, options = {})
        attribute name, type, { strict: true }.merge(options)
      end
    end
  end

  class << self
    attr_accessor :configuration
  end

  def self.configure(&block)
    @configuration = Class.new { include Configurable }.tap(&block)
    # or define this thing as ENVied::Configuration? prolly not threadsafe
  ensure
    @instance = nil
  end

  def self.instance
    @instance ||= @configuration.parse_env(ENV.to_hash)
  end
  class << self
    alias_method :require!, :instance
  end

  def self.[](key)
    instance.attributes[key]
    #instance[key] # will raise and complain that <class <>> doesn't response; better?
  end

  def self.method_missing(method, *args, &block)
    respond_to_missing?(method) ? instance.public_send(method, *args, &block) : super
  end

  def self.respond_to_missing?(method, include_private = false)
    instance.attributes.key?(method) || super
  end
end
