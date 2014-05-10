class ENVied
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

        class << self
          attr_accessor :enable_defaults
        end
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
          variable = attribute_set[name]
          default = variable.options[:default]
          value = env[name.to_s] || env[name.to_s.upcase]
          if !(value || default)
            raise VariableMissingError, variable
          end

          try_coercion(variable, value, default)
          result[name] = value if value
        end

        new(atts)
      end

      # Define a variable.
      #
      # @param name [Symbol] name of the variable
      # @param type [Symbol] type (one of :String (default), :Symbol, :Integer, :Boolean,
      #   :Date, :Time)
      # @param options [Hash]
      # @option options [String, Integer, Boolean, #call] :default (nil) what value will be
      #   used when no ENV-variable is present.
      # @note Defaults are ignored by default, see {configure}.
      #
      def variable(name, type = :String, options = {})
        options.delete(:default) unless self.enable_defaults
        attribute name, type, { strict: true }.merge(options)
      end

      private
      def try_coercion(variable, value, default)
        value ||= begin
          default unless default.respond_to?(:call)
        end
        return unless value
        @variable = variable

        variable.coerce(value)
      rescue Virtus::CoercionError => e
        raise VariableTypeError.new(@variable)
      end
    end
  end

  class << self
    attr_accessor :configuration
  end

  # Configure ENVied.
  #
  # @param options [Hash]
  # @option options [Boolean] :enable_defaults (false) whether or not defaults are used.
  #
  # @example
  #   ENVied.configure(enable_defaults: Rails.env.development?) do
  #     variable :force_ssl, :Boolean, default: false
  #   end
  #
  def self.configure(options = {}, &block)
    options = { enable_defaults: false }.merge(options)
    @configuration = Class.new { include Configurable }.tap do |k|
      k.enable_defaults = options[:enable_defaults]
      k.instance_eval(&block)
    end
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
